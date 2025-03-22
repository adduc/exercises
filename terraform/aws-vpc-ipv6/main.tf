##
# Exercise: Creating AWS resources using IPv6 where possible
#
# Notes:
# - RDS and ALB support dualstack IPv6, but do not support IPv6-only.
##

provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      app = "free-tier-ipv6"
    }
  }
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

  name               = "ipv6-vpc"
  enable_ipv6        = true
  enable_nat_gateway = false

  azs  = slice(data.aws_availability_zones.available.names, 0, 3)
  cidr = "10.0.0.0/16"

  public_subnets                                = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  public_subnet_ipv6_prefixes                   = [0, 1, 2]
  public_subnet_assign_ipv6_address_on_creation = true

  private_subnet_ipv6_native   = true
  private_subnet_ipv6_prefixes = [3, 4, 5]

  database_subnets              = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  database_subnet_ipv6_prefixes = [6, 7, 8]
}

##
# RDS, Option Group, Parameter Group, etc.
#
# @see https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/latest
##

resource "aws_security_group" "rds" {
  name        = "free-tier-rds-security-group"
  description = "Security group for free-tier RDS instance"
  vpc_id      = module.vpc.vpc_id
}

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "free-tier"
  db_name    = "free_tier_db"

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
  username                            = "free_tier_admin"
  iam_database_authentication_enabled = true

  ## Network
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [aws_security_group.rds.id]
  network_type           = "DUAL"

  ## Security
  deletion_protection = false
  skip_final_snapshot = true
}

##
# ALB, Target Group, Listener, etc.
#
# @see https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest
##

module "lb" {
  source             = "terraform-aws-modules/alb/aws"
  name               = "free-tier"
  load_balancer_type = "application"

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  ip_address_type = "dualstack-without-public-ipv4"

  enable_deletion_protection = false
}

output "lb_dns_name" {
  value = module.lb.dns_name
}