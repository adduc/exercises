# Exercise: Golang-based Lambda without external libraries

## Context

I was interested in how AWS starts and invokes lambda code, and was interested in using TinyGo to build a lightweight solution that could potentially reduce cold start times. This exercise explored the minimal required code to successfully start, accept events, and return responses using the Lambda Runtime API.

## Requirements

- Terraform
- AWS CLI
- Go

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

### TinyGo

TinyGo does not fully implement the `net/http` package to the extent that requests can be made. This would prevent using TinyGo with the Lambda Runtime API to receive events. It might be possible to bring in a third-party package that implements alternatives to the `net/http` package, or to use the internal RPC mechanism to accept requests from AWS.

### Speed

This exercise cold starts in around ~50-80ms, which is around the same time as the aws-lambda-go library, while it is slightly slower (~0.1-0.3ms) in per-request time. While there might be potential to bring in the performance optimizations in the aws-lambda-go library, it seems there is not a lot of performance left on the table.