## Inputs

variable "notification_email" {
  type        = string
  description = <<-EOT
    The email address to notify when the budget is exceeded.
  EOT
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
