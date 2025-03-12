# Exercise: Bash-based Lambda Function

## Context

I am looking at creating Lambda functions for a few projects, and I wanted to better understand how Lambdas are expected to communicate with AWS to handle events. As I am comfortable with shell scripting, I thought it would be interesting to create a Lambda function in Bash.

## Requirements

- Terraform
- AWS CLI

## Setup

The Terraform code in this exercise creates a Lambda function that is triggered by an S3 event. The Lambda function is written in Bash and is designed to handle the event by printing the event details to the console.

To provision the lambda function and related resources, run the following commands:

```sh

terraform init
terraform apply
```

## Deploying the Lambda Function

A Makefile is provided to help with the deployment process. The Makefile includes a target to build the Lambda function, archive it, and update the Lambda function code in AWS.
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