# Running Gin in a Lambda

This exercise demonstrates how an adapter for the `net/http` package can be used to run a Gin web server in an AWS Lambda function.

## Context

I had some trouble setting exposing a Lambda to web traffic using Gin,
and wanted to create the resources in a sandbox to identify all the
steps needed to get it working.

## Infrastructure

The infrastructure is created using Terraform. It creates a Lambda function and an API Gateway to expose the Lambda to the web.

To create the infrastructure, run the following commands:

```sh
terraform init
terraform apply
```

## Deploying the Lambda

A Makefile is provided to build the Lambda function and deploy it to AWS. To deploy the Lambda, run the following command:

```sh
make pipeline
```

This will build the Lambda function, create a zip file, and update the Lambda function.