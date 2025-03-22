##
# Exercise: running a free-tier OpenSearch cluster
##

locals {
  app = "freetier-opensearch"
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

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

##
# OpenSearch Cluster, security group, etc.
##

module "opensearch" {
  source  = "terraform-aws-modules/opensearch/aws"
  version = "1.6.0"

  domain_name = local.app

  advanced_security_options = {
    enabled = false
  }

  # Autotune is not supported in t2/t3 instance types.
  auto_tune_options = {
    desired_state = "DISABLED"
  }

  ebs_options = {
    ebs_enabled = true
    volume_size = 10
  }

  cluster_config = {
    dedicated_master_enabled = false
    instance_count           = 1
    instance_type            = "t3.small.search"
    zone_awareness_enabled   = false
  }

  security_group_rules = {
    ingress = {
      type        = "ingress"
      description = "Allow traffic from the VPC"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  vpc_options = {
    subnet_ids = [module.vpc.private_subnets[0]]
  }
}

## Outputs

output "opensearch_dashboard_endpoint" {
  value = module.opensearch.domain_dashboard_endpoint
}

output "opensearch_endpoint" {
  value = module.opensearch.domain_endpoint
}
