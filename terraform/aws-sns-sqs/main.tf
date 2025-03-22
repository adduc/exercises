## Local Variables

locals {
  topic_name = "my-sns-topic"
}

## Data Sources

data "aws_caller_identity" "current" {}

## Resources

# sns topic

resource "aws_sns_topic" "sns_topic" {
  name = local.topic_name

  # on failure writing to sqs queue, log to cloudwatch
  sqs_failure_feedback_role_arn = aws_iam_role.sns.arn

  # on success writing to sqs queue, log to cloudwatch
  sqs_success_feedback_role_arn    = aws_iam_role.sns.arn
  sqs_success_feedback_sample_rate = 100
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

# sqs queue

resource "aws_sqs_queue" "sqs_queue" {
  name = "my-sqs-queue"
}

data "aws_iam_policy_document" "sqs_queue" {
  # allow sns to write to sqs queue
  statement {
    sid       = "SQS"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.sqs_queue.arn]
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
  }
}

resource "aws_sqs_queue_policy" "sqs_queue_policy" {
  queue_url = aws_sqs_queue.sqs_queue.id
  policy    = data.aws_iam_policy_document.sqs_queue.json
}

# sns topic subscription

resource "aws_sns_topic_subscription" "my_sns_topic_subscription" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.sqs_queue.arn
}

