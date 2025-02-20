## Required Providers

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

## Providers

provider "aws" {
  region = "us-east-2"
}

## Resources
# @see https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "free-tier-rds"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-2a", "us-east-2b", "us-east-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  # Cluster
  cluster_name = "free-tier"

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

  name = "free-tier"

  min_size              = 0
  max_size              = 1
  desired_capacity      = 1
  vpc_zone_identifier   = module.vpc.public_subnets
  force_delete          = true
  protect_from_scale_in = true

  # Launch Template
  launch_template_name   = "free-tier"
  update_default_version = true
  image_id               = data.aws_ssm_parameter.ecs_ami.value
  instance_type          = "t3.micro"

  # Launch Template's IAM
  create_iam_instance_profile = true
  iam_role_name               = "ecs_instance"
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
}

resource "aws_security_group" "autoscaling" {
  name   = "free-tier"
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

resource "aws_vpc_security_group_ingress_rule" "all_ssh" {
  security_group_id = aws_security_group.autoscaling.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = "0.0.0.0/0"
}


module "ecs_service" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name                     = "free-tier"
  cluster_arn              = module.ecs.cluster_arn
  requires_compatibilities = ["EC2"]
  launch_type              = "EC2"

  cpu    = 128
  memory = 128

  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 1
  desired_count            = 1

  container_definitions = {
    nginx = {
      cpu                      = 128
      memory                   = 128
      essential                = true
      image                    = "nginx:latest"
      readonly_root_filesystem = false
      port_mappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.lb.target_groups["ecs"].arn
      container_name   = "nginx"
      container_port   = 80
    }
  }

  subnet_ids = module.vpc.public_subnets
  security_group_rules = {
    alb_ingress = {
      type                     = "ingress"
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      source_security_group_id = module.lb.security_group_id
    }
  }
}

# @see https://github.com/terraform-aws-modules/terraform-aws-alb
module "lb" {
  source             = "terraform-aws-modules/alb/aws"
  name               = "free-tier"
  load_balancer_type = "application"

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  enable_deletion_protection = false
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
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
      backend_protocol  = "HTTP"
      backend_port      = 80
      target_type       = "ip"
      create_attachment = false
    }
  }
}

output "lb_dns_name" {
  value = module.lb.dns_name
}
