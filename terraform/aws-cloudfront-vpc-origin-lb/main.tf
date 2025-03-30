##
# Exercise: Creating AWS resources using IPv6 where possible
#
# Notes:
# - RDS and ALB support dualstack IPv6, but do not support IPv6-only.
##

locals {
  app = "cloudfront-vpc-origin"
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

## Required Providers

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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

  public_subnets  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  private_subnets = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
}

##
# Cloudfront, Cache Behavior, etc.
#
# @see https://registry.terraform.io/modules/terraform-aws-modules/cloudfront/aws/latest
##

module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "~> 4.0"

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
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name                       = local.app
  load_balancer_type         = "application"
  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.private_subnets
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

## Outputs

output "cloudfront_domain_name" {
  value = module.cloudfront.cloudfront_distribution_domain_name
}

output "load_balancer_dns_name" {
  value = module.lb.dns_name
}