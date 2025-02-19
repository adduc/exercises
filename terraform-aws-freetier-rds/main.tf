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

# @see https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/latest

resource "aws_security_group" "rds" {
  name        = "free-tier-rds-security-group"
  description = "Security group for free-tier RDS instance"
  vpc_id      = module.vpc.vpc_id
}

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "free-tier-rds"

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
  create_db_subnet_group = true
  subnet_ids             = module.vpc.private_subnets
  vpc_security_group_ids = [aws_security_group.rds.id]

  ## Security
  deletion_protection = false
  skip_final_snapshot = true
}

output "rds_endpoint" {
  value = module.db.db_instance_address
}