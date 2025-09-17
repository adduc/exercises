locals {
  app_name = "golang_lambda_scratch"
}

provider "aws" {
  default_tags {
    tags = {
      App = local.app_name
    }
  }
}

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_lambda_function" "lambda" {
  function_name = local.app_name
  role          = aws_iam_role.lambda_exec.arn
  handler       = "main"
  runtime       = "provided.al2023"
  filename      = "empty.zip" # echo | zip -q > empty.zip

  # use logs group from cloudwatch
  logging_config {
    log_group             = aws_cloudwatch_log_group.log_group.name
    log_format            = "JSON"
    system_log_level      = "DEBUG"
    application_log_level = "DEBUG"
  }
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = local.app_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda_exec_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role_policy" "lambda_exec_policy" {
  name   = "${local.app_name}_policy"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_exec_policy.json
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/lambda/${local.app_name}"
  retention_in_days = 7
}