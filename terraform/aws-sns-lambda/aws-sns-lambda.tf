## Local Variables

locals {
  topic_name  = "my-sns-topic"
  lambda_name = "my-lambda-function"
}

## Providers

provider "aws" {
  default_tags {
    tags = {
      app = "sns-lambda-integration"
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

## Resources

# sns topic

resource "aws_sns_topic" "sns_topic" {
  name = local.topic_name

  # on failure writing to sqs queue, log to cloudwatch
  lambda_failure_feedback_role_arn = aws_iam_role.sns.arn

  # on success writing to sqs queue, log to cloudwatch
  lambda_success_feedback_role_arn    = aws_iam_role.sns.arn
  lambda_success_feedback_sample_rate = 100
}

resource "aws_cloudwatch_log_group" "sns_log_group_failure" {
  name = format(
    "sns/us-east-2/%s/%s/Failure",
    data.aws_caller_identity.current.account_id,
    local.topic_name
  )
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "sns_log_group_success" {
  name = format(
    "sns/us-east-2/%s/%s",
    data.aws_caller_identity.current.account_id,
    local.topic_name
  )
  retention_in_days = 14
}

resource "aws_iam_role" "sns" {
  name = "my-sqs-sns-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "sns.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

data "aws_iam_policy_document" "sns" {
  # allow sns to write to cloudwatch logs
  statement {
    sid = "LogGroup"
    actions = [
      "logs:CreateLogGroup"
    ]

    resources = [
      aws_cloudwatch_log_group.sns_log_group_failure.arn,
      aws_cloudwatch_log_group.sns_log_group_success.arn,
    ]
  }

  statement {
    sid = "LogStream"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.sns_log_group_failure.arn}:log-stream:*",
      "${aws_cloudwatch_log_group.sns_log_group_success.arn}:log-stream:*",
    ]
  }
}

resource "aws_iam_role_policy" "sns" {
  name   = "inline_policy"
  role   = aws_iam_role.sns.id
  policy = data.aws_iam_policy_document.sns.json
}

# lambda

resource "aws_lambda_function" "lambda" {
  function_name = local.lambda_name
  handler       = "lambda.lambda_handler"
  runtime       = "python3.13"
  filename      = "${path.module}/lambda.zip"
  role          = aws_iam_role.lambda.arn

  logging_config {
    log_group             = aws_cloudwatch_log_group.lambda_log_group.name
    log_format            = "JSON"
    application_log_level = "DEBUG"
    system_log_level      = "DEBUG"
  }
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name = format(
    "lambda/us-east-2/%s/%s",
    data.aws_caller_identity.current.account_id,
    local.lambda_name
  )
  retention_in_days = 14
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = local.lambda_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda" {
  # allow lambda to write to cloudwatch logs
  statement {
    sid = "LogGroup"
    actions = [
      "logs:CreateLogGroup"
    ]

    resources = [
      aws_cloudwatch_log_group.lambda_log_group.arn,
    ]
  }

  statement {
    sid = "LogStream"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.lambda_log_group.arn}:log-stream:*",
    ]
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "inline_policy"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda.json
}

# sns to lambda

resource "aws_lambda_permission" "sns_to_lambda" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = local.lambda_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.sns_topic.arn
}

resource "aws_sns_topic_subscription" "sns_to_lambda" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda.arn
}