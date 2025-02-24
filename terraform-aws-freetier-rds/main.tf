##
# Exercise: Free-tier-eligible RDS instance (MariaDB)
##

locals {
  app = "freetier-rds-mariadb"
}

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

  default_tags {
    tags = {
      app = local.app
    }
  }
}

## Data Sources

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

output "rds_endpoint" {
  value = module.db.db_instance_address
}