# Exercise: Bash-based Lambda Function

## Context

I am looking at creating Lambda functions for a few projects, and I wanted to better understand how Lambdas are expected to communicate with AWS to handle events. As I am comfortable with shell scripting, I thought it would be interesting to create a Lambda function in Bash.

## Requirements

- Terraform
- AWS CLI

## Infrastructure Setup

The Terraform code in this exercise creates a Lambda function and related resources.

To set up the infrastructure, run the following commands:

```sh
cd infra
terraform init
terraform apply
```

## Deploying the Lambda Function

A Makefile is provided to help with the deployment process. The Makefile
includes a target to build the Lambda function, create an archive, and
update the Lambda function code in AWS.

To deploy the Lambda function, run:

```sh
make deploy
```

## Testing the Lambda Function

The Makefile also includes a target to test the Lambda function. To test the function, run:

```sh
make invoke
```

This will invoke the Lambda function with a sample event and print the output to the console.

## Lessons Learned

Bash takes around ~40-50ms to cold start, which is faster than most other languages. However, it is slower to serve requests, averaging around ~200ms per request. It is not a good choice when speed is a concern.