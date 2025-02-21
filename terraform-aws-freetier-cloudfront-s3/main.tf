# Free-Tier Cloudfront Distribution for S3 Bucket

## Providers

provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      app = "free-tier-cloudfront-s3"
    }
  }
}

## Data Sources

data "aws_organizations_organization" "current" {}

## Resources / Modules

# @see https://github.com/terraform-aws-modules/terraform-aws-cloudfront
module "cloudfront" {
  source = "terraform-aws-modules/cloudfront/aws"

  create_origin_access_identity = true
  origin_access_identities = {
    s3_bucket = "s3 bucket"
  }

  origin = {
    s3_origin = {
      domain_name = module.s3_bucket.s3_bucket_bucket_regional_domain_name
      s3_origin_config = {
        origin_access_identity = "s3_bucket"
      }
    }
  }

  default_cache_behavior = {
    target_origin_id       = "s3_origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"]
  }

  default_root_object = "index.html"

  custom_error_response = {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/error.html"
    error_caching_min_ttl = 24 * 60 * 60
  }

  geo_restriction = {
    restriction_type = "none"
  }
}

# @see https://github.com/terraform-aws-modules/terraform-aws-s3-bucket
module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = format(
    "%s-free-tier-cloudfront-s3",
    data.aws_organizations_organization.current.master_account_name
  )

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  attach_policy = true
  policy        = data.aws_iam_policy_document.bucket.json
}

data "aws_iam_policy_document" "bucket" {
  statement {
    sid       = "AllowCloudfrontAccessToBucket"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${module.s3_bucket.s3_bucket_arn}/*"]

    principals {
      type        = "AWS"
      identifiers = module.cloudfront.cloudfront_origin_access_identity_iam_arns
    }
  }
}

resource "aws_s3_object" "index" {
  bucket       = module.s3_bucket.s3_bucket_id
  key          = "index.html"
  content_type = "text/html"
  content      = "<html><body><h1>Hello, World</h1></body></html>"
}

resource "aws_s3_object" "error" {
  bucket       = module.s3_bucket.s3_bucket_id
  key          = "error.html"
  content_type = "text/html"
  content      = "<html><body><h1>Oops, something went wrong</h1></body></html>"
}

## Outputs

output "cloudfront_domain_name" {
  value = module.cloudfront.cloudfront_distribution_domain_name
}