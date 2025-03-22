##
# Exercise: running wordpress in AWS using free-tier resources
#
# Netflow:
#   Cloudfront -> ALB -> ECS (EC2) -> RDS (MariaDB)
#
# Potential Improvements:
# - S3 Terraform Backend
##

provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      app = local.app
    }
  }
}

locals {
  app = "wordpress"
}

data "aws_availability_zones" "available" {}

##
# VPC, subnets, internet gateway, route tables, etc.
#
# @see https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
##
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name               = local.app
  enable_nat_gateway = false

  azs  = slice(data.aws_availability_zones.available.names, 0, 3)
  cidr = "10.0.0.0/16"

  public_subnets   = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  private_subnets  = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  database_subnets = ["10.0.31.0/24", "10.0.32.0/24", "10.0.33.0/24"]
}

##
# RDS, Option Group, Parameter Group, etc.
#
# @see https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/latest
##

resource "aws_security_group" "rds" {
  name        = "${local.app}-rds"
  description = "Security group for free-tier RDS instance"
  vpc_id      = module.vpc.vpc_id
}

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = local.app
  db_name    = local.app

  ## Engine
  engine               = "mariadb"
  engine_version       = "11.4"
  major_engine_version = "11.4"
  family               = "mariadb11.4"

  ## Compute
  instance_class = "db.t4g.micro"

  ## Storage
  allocated_storage = 20
  storage_type      = "gp2"

  ## Authentication
  username                            = "${local.app}_admin"
  iam_database_authentication_enabled = true

  ## Network
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  subnet_ids             = module.vpc.private_subnets
  vpc_security_group_ids = [aws_security_group.rds.id]

  ## Security
  deletion_protection = false
  skip_final_snapshot = true
}

##
# Cloudfront, Cache Behavior, etc.
#
# @see https://registry.terraform.io/modules/terraform-aws-modules/cloudfront/aws/latest
##

module "cloudfront" {
  source = "terraform-aws-modules/cloudfront/aws"

  origin = {
    vpc_origin = {
      domain_name = module.lb.dns_name
      vpc_origin_config = {
        vpc_origin_id = aws_cloudfront_vpc_origin.vpc_origin.id
      }
    }
  }

  default_cache_behavior = {
    target_origin_id       = "vpc_origin"
    viewer_protocol_policy = "redirect-to-https"

    compress                  = true
    headers                   = ["Origin", "Host"]
    cookies_forward           = "whitelist"
    cookies_whitelisted_names = ["comment_*", "wordpress_*", "wp-settings-*"]
    query_string              = true

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"]

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  geo_restriction = {
    restriction_type = "none"
  }
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

##
# ALB, Target Group, Listener, etc.
#
# @see https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest
##

module "lb" {
  source                     = "terraform-aws-modules/alb/aws"
  name                       = local.app
  load_balancer_type         = "application"
  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.public_subnets
  enable_deletion_protection = false

  # Since we are using Cloudfront's VPC origin feature, the load
  # balancer does not need to be internet-facing.
  internal = true

  security_group_ingress_rules = {
    cloudfront_http = {
      from_port      = 80
      to_port        = 80
      ip_protocol    = "tcp"
      prefix_list_id = data.aws_ec2_managed_prefix_list.cloudfront.id
    }
  }

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "ecs"
      }
    }
  }

  target_groups = {
    ecs = {
      backend_protocol             = "HTTP"
      backend_port                 = 8080
      target_type                  = "ip"
      create_attachment            = false
      deregistration_delay_timeout = 15

      health_check = {
        path                = "/"
        interval            = 30
        timeout             = 10
        healthy_threshold   = 3
        unhealthy_threshold = 3
      }
    }
  }
}

resource "aws_cloudfront_vpc_origin" "vpc_origin" {
  vpc_origin_endpoint_config {
    name                   = local.app
    arn                    = module.lb.arn
    http_port              = 80
    https_port             = 443
    origin_protocol_policy = "http-only"

    origin_ssl_protocols {
      items    = ["TLSv1.2"]
      quantity = 1
    }
  }
}

##
# ECS
#
# @see https://registry.terraform.io/modules/terraform-aws-modules/ecs/aws/latest
##
module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  # Cluster
  cluster_name = local.app

  cluster_settings = [
    {
      name  = "containerInsights"
      value = "disabled"
    }
  ]

  default_capacity_provider_use_fargate = false

  autoscaling_capacity_providers = {
    ec2 = {
      auto_scaling_group_arn         = module.autoscaling.autoscaling_group_arn
      managed_termination_protection = "ENABLED"
      managed_scaling = {
        status = "ENABLED"
      }
    }
  }
}

# @see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/retrieve-ecs-optimized_AMI.html
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

# @see https://github.com/terraform-aws-modules/terraform-aws-autoscaling
module "autoscaling" {
  source = "terraform-aws-modules/autoscaling/aws"

  name = local.app

  min_size              = 0
  max_size              = 1
  desired_capacity      = 1
  vpc_zone_identifier   = module.vpc.public_subnets
  force_delete          = true
  protect_from_scale_in = true

  # Launch Template
  launch_template_name   = local.app
  update_default_version = true
  image_id               = data.aws_ssm_parameter.ecs_ami.value
  instance_type          = "t3.micro"

  # Launch Template's IAM
  create_iam_instance_profile = true
  iam_role_name               = "${local.app}-ecs-instance"
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  network_interfaces = [
    {
      associate_public_ip_address = true
      delete_on_termination       = true
      security_groups             = [aws_security_group.autoscaling.id]
    }
  ]

  user_data = base64encode(
    <<-EOF
      #!/bin/bash
      # Ensure we register with the correct cluster
      # @see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_container_instance.html
      echo ECS_CLUSTER=${module.ecs.cluster_name} >> /etc/ecs/ecs.config

      # Prevent ECS tasks from accessing EC2 instance metadata
      # @see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security-iam-roles.html#security-iam-roles-recommendations
      echo ECS_AWSVPC_BLOCK_IMDS=true >> /etc/ecs/ecs.config

      # Enable SSM for auditable terminal access
      systemctl enable --now amazon-ssm-agent
    EOF
  )

  autoscaling_group_tags = {
    AmazonECSManaged = true
  }
}

resource "aws_security_group" "autoscaling" {
  name   = "${local.app}-ecs-instance"
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "all_ipv4" {
  security_group_id = aws_security_group.autoscaling.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "all_ipv6" {
  security_group_id = aws_security_group.autoscaling.id
  ip_protocol       = "-1"
  cidr_ipv6         = "::/0"
}

##
# ECS Service
##

module "efs" {
  source = "terraform-aws-modules/efs/aws"

  name                 = local.app
  enable_backup_policy = false
  encrypted            = false

  access_points = {
    root = {
      root_directory = {
        path = "/"
        creation_info = {
          owner_uid   = 1001
          owner_gid   = 1001
          permissions = "750"
        }
      }
    }
  }

  mount_targets = {
    for az in data.aws_availability_zones.available.names : az => {
      subnet_id = element(module.vpc.private_subnets, index(data.aws_availability_zones.available.names, az))
    }
  }

  security_group_vpc_id = module.vpc.vpc_id
  security_group_rules = {
    vpc = {
      source_security_group_id = module.ecs_service.security_group_id
    }
  }
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = module.db.db_instance_master_user_secret_arn
}

module "ecs_service" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name                               = local.app
  cluster_arn                        = module.ecs.cluster_arn
  requires_compatibilities           = ["EC2"]
  launch_type                        = "EC2"
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100
  health_check_grace_period_seconds  = 180

  autoscaling_policies = {}

  cpu    = 256
  memory = 256

  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 1
  desired_count            = 1

  container_definitions = {
    wordpress = {
      cpu                      = 256
      memory                   = 256
      essential                = true
      image                    = "public.ecr.aws/bitnami/wordpress:latest"
      readonly_root_filesystem = false
      port_mappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      # @see https://github.com/bitnami/containers/blob/main/bitnami/wordpress/README.md#environment-variables
      environment = [
        {
          name  = "WORDPRESS_DATABASE_HOST"
          value = module.db.db_instance_address
        },
        {
          name  = "WORDPRESS_DATABASE_USER"
          value = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["username"]
        },
        {
          name  = "WORDPRESS_DATABASE_PASSWORD"
          value = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["password"]
        },
        {
          name  = "WORDPRESS_DATABASE_NAME"
          value = module.db.db_instance_name
        },
        {
          name  = "WORDPRESS_EXTRA_WP_CONFIG_CONTENT"
          value = <<-EOT
            // Force HTTPS
            $_SERVER['HTTPS'] = 'on';
          EOT
        }
      ]
      mount_points = [
        {
          sourceVolume  = "wordpress"
          containerPath = "/bitnami/wordpress"
        }
      ]
    }
  }

  volume = [
    {
      name = "wordpress"
      efs_volume_configuration = {
        file_system_id     = module.efs.id
        transit_encryption = "ENABLED"
      }
    }
  ]

  load_balancer = {
    service = {
      target_group_arn = module.lb.target_groups["ecs"].arn
      container_name   = "wordpress"
      container_port   = 8080
    }
  }

  subnet_ids = module.vpc.public_subnets
  security_group_rules = {
    alb_ingress = {
      type                     = "ingress"
      from_port                = 8080
      to_port                  = 8080
      protocol                 = "tcp"
      source_security_group_id = module.lb.security_group_id
    }

    db_egress = {
      type                     = "egress"
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      source_security_group_id = aws_security_group.rds.id
    }

    efs_egress = {
      type                     = "egress"
      from_port                = 2049
      to_port                  = 2049
      protocol                 = "tcp"
      source_security_group_id = module.efs.security_group_id
    }
  }
}


resource "aws_vpc_security_group_ingress_rule" "ec2_to_rds" {
  security_group_id            = aws_security_group.rds.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  referenced_security_group_id = module.ecs_service.security_group_id
}

## Outputs

output "cloudfront_domain_name" {
  value = module.cloudfront.cloudfront_distribution_domain_name
}

output "load_balancer_dns_name" {
  value = module.lb.dns_name
}