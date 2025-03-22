# Exercise: Creating an SNS Topic forwarding to a Lambda Function

This exercise demonstrates how an SNS topic can be created to forward
messages directly to a Lambda function. Both the SNS topic delivery and
the Lambda function execution are logged to CloudWatch Logs.

## Context

I had some trouble setting up an SNS topic to forward messages for
another project, and wanted to create the resources in a sandbox to
identify all of the resources necessary to make this work.