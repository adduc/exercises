##
# Creating a free-tier-eligible Cloudtrail to audit events across
# all accounts in an AWS Organization
##

locals {
  app          = "freetier-cloudtrail"
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

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_organizations_organization" "current" {}

##
# Cloudtrail
##
resource "aws_cloudtrail" "org_cloudtrail" {
  name                          = local.app
  s3_bucket_name                = aws_s3_bucket.bucket.id
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.log_group.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloud_watch_logs_role.arn
  include_global_service_events = true
  is_organization_trail         = true
  is_multi_region_trail         = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [aws_s3_bucket_policy.bucket_policy]
}

##
# S3 Bucket
##

resource "aws_s3_bucket" "bucket" {
  bucket        = "${local.account_name}-${local.app}"
  force_destroy = true
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid    = "S3GetBucketAcl"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.bucket.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values = [
        format(
          "arn:%s:cloudtrail:%s:%s:trail/%s",
          data.aws_partition.current.partition,
          data.aws_region.current.name,
          data.aws_organizations_organization.current.master_account_id,
          local.app
        )
      ]
    }
  }

  statement {
    sid    = "S3PutObject"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["s3:PutObject"]
    resources = [
      format(
        "%s/AWSLogs/%s/*",
        aws_s3_bucket.bucket.arn,
        data.aws_organizations_organization.current.master_account_id
      )
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values = [
        format(
          "arn:%s:cloudtrail:%s:%s:trail/%s",
          data.aws_partition.current.partition,
          data.aws_region.current.name,
          data.aws_organizations_organization.current.master_account_id,
          local.app
        )
      ]
    }
  }

  statement {
    sid    = "OrgS3PutObject"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = ["s3:PutObject"]
    resources = [
      format(
        "%s/AWSLogs/%s/*",
        aws_s3_bucket.bucket.arn,
        data.aws_organizations_organization.current.id
      )
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values = [
        format(
          "arn:%s:cloudtrail:%s:%s:trail/%s",
          data.aws_partition.current.partition,
          data.aws_region.current.name,
          data.aws_organizations_organization.current.master_account_id,
          local.app
        )
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

## CloudWatch Logs

resource "aws_cloudwatch_log_group" "log_group" {
  name = local.app
}

data "aws_iam_policy_document" "cloud_watch_logs_role_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cloud_watch_logs_role_policy" {
  statement {
    sid = "CreateLogStream"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect = "Allow"
    resources = [
      format(
        "arn:%s:logs:%s:%s:log-group:%s:log-stream:%s_CloudTrail_%s*",
        data.aws_partition.current.partition,
        data.aws_region.current.name,
        data.aws_caller_identity.current.account_id,
        aws_cloudwatch_log_group.log_group.name,
        data.aws_caller_identity.current.account_id,
        data.aws_region.current.name
      ),
      format(
        "arn:%s:logs:%s:%s:log-group:%s:log-stream:%s_*",
        data.aws_partition.current.partition,
        data.aws_region.current.name,
        data.aws_caller_identity.current.account_id,
        aws_cloudwatch_log_group.log_group.name,
        data.aws_organizations_organization.current.id
      )
    ]
  }
}

resource "aws_iam_role" "cloud_watch_logs_role" {
  name               = "${local.app}-cloudwatch-logs"
  assume_role_policy = data.aws_iam_policy_document.cloud_watch_logs_role_assume.json
  inline_policy {
    name   = "cloud_watch_logs_role_policy"
    policy = data.aws_iam_policy_document.cloud_watch_logs_role_policy.json
  }
}