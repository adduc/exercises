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

  name = "free-tier-opensearch"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-2a", "us-east-2b", "us-east-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

# @see https://registry.terraform.io/modules/terraform-aws-modules/opensearch/aws/latest
module "opensearch" {
  source  = "terraform-aws-modules/opensearch/aws"
  version = "1.6.0"

  domain_name = "freetier-opensearch"

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

data "aws_iam_policy_document" "opensearch_master_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["es.amazonaws.com"]
    }
  }
}

output "opensearch_dashboard_endpoint" {
  value = module.opensearch.domain_dashboard_endpoint
}

output "opensearch_endpoint" {
  value = module.opensearch.domain_endpoint
}
