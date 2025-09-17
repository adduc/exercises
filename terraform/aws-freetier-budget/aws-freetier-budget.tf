## Inputs

variable "notification_email" {
  type        = string
  description = <<-EOT
    The email address to notify when the budget is exceeded.
  EOT
}

## Providers

provider "aws" {}

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

## Resources

# @see https://us-east-1.console.aws.amazon.com/billing/home?region=us-east-1#/budgets/details?name=My%20Zero-Spend%20Budget
resource "aws_budgets_budget" "freetier" {
  name         = "My Zero-Spend Budget"
  budget_type  = "COST"
  limit_amount = "1.0"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 0.01
    threshold_type             = "ABSOLUTE_VALUE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.notification_email]
  }
}
