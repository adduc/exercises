##
# Exercise: Creating a free-tier-eligible Cloudfront Distribution backed
# by an S3 Bucket
##

locals {
  app          = "cloudfront-s3-scratch"
  account_name = data.aws_organizations_organization.current.master_account_name
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

data "aws_organizations_organization" "current" {}

## Resources

# S3 Bucket

resource "aws_s3_bucket" "bucket" {
  bucket        = "${local.account_name}-${local.app}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "bucket" {
  statement {
    sid       = "AllowCloudfrontAccessToBucket"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket" {
  bucket = aws_s3_bucket.bucket.bucket
  policy = data.aws_iam_policy_document.bucket.json
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.bucket.bucket
  key          = "index.html"
  content_type = "text/html"
  content      = "<html><body><h1>Hello, World</h1></body></html>"
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.bucket.bucket
  key          = "error.html"
  content_type = "text/html"
  content      = "<html><body><h1>Oops, something went wrong</h1></body></html>"
}

# Cloudfront Distribution

resource "aws_cloudfront_distribution" "distribution" {
  enabled             = true
  default_root_object = "index.html"

  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/error.html"
    error_caching_min_ttl = 24 * 60 * 60
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "S3-bucket"
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = aws_cloudfront_cache_policy.cache_policy.id
  }

  origin {
    domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id   = "S3-bucket"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = local.app
}

resource "aws_cloudfront_cache_policy" "cache_policy" {
  name        = local.app
  default_ttl = 24 * 60 * 60
  min_ttl     = 24 * 60 * 60
  max_ttl     = 24 * 60 * 60

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

## Outputs

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.distribution.domain_name
}