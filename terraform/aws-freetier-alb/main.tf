##
# Exercise: a free-tier-elgible ALB
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
  app = "freetier-alb"
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

  name = local.app
  cidr = "10.0.0.0/16"

  azs             = ["us-east-2a", "us-east-2b", "us-east-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

##
# ALB, Target Group, Listener, etc.
#
# @see https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest
##
module "alb" {
  source                     = "terraform-aws-modules/alb/aws"
  name                       = local.app
  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.public_subnets
  enable_deletion_protection = false

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      fixed_response = {
        content_type = "text/plain"
        message_body = "^_^"
        status_code  = "200"
      }
    }
  }
}

## Outputs

output "alb_dns_name" {
  value = module.alb.dns_name
}