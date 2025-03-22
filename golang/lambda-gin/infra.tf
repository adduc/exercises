## Inputs

variable "lambda_name" {
  description = "Name of the Lambda function"
  type        = string
}

## Provider

provider "aws" {
  default_tags {
    tags = {
      App = "golang-lambda-gin"
    }
  }
}

## Required Providers

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

## Resources

resource "aws_lambda_function" "lambda_function" {
  function_name = var.lambda_name
  role          = aws_iam_role.lambda_role.arn
  runtime       = "provided.al2023"
  handler       = "index.handler"
  filename      = "empty.zip"

  logging_config {
    log_group             = aws_cloudwatch_log_group.lambda_log_group.name
    log_format            = "JSON"
    system_log_level      = "DEBUG"
    application_log_level = "DEBUG"
  }
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/exercise/golang-lambda-gin/${var.lambda_name}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = var.lambda_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda" {
  statement {
    sid = "LogGroup"
    actions = [
      "logs:CreateLogGroup"
    ]

    resources = [
      aws_cloudwatch_log_group.lambda_log_group.arn
    ]
  }

  statement {
    sid = "LogStream"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.lambda_log_group.arn}:log-stream:*"
    ]
  }
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "inline_policy"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda.json
}

# API Gateway

resource "aws_apigatewayv2_api" "api" {
  name          = var.lambda_name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.lambda_function.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.integration.id}"
}

resource "aws_lambda_permission" "lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  # The source ARN is the API Gateway endpoint
  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_deployment" "deployment" {
  api_id = aws_apigatewayv2_api.api.id

  triggers = {
    redeployment = sha1(join(",", [
      aws_apigatewayv2_integration.integration.id,
      aws_apigatewayv2_route.route.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_apigatewayv2_stage" "stage" {
  api_id        = aws_apigatewayv2_api.api.id
  name          = "$default"
  deployment_id = aws_apigatewayv2_deployment.deployment.id
}

## Outputs

output "api_gateway_url" {
  description = "The URL of the API Gateway endpoint"
  value       = aws_apigatewayv2_api.api.api_endpoint
}