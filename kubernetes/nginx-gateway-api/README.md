# Using Kubernetes' Gateway API with Nginx Gateway Fabric

This exercise demonstrates how traffic can be routed to a service using the Gateway API and Nginx Gateway Fabric.

## Context

I have previously worked with Nginx Gateway Fabric and its integration with the Gateway API when it initially launched, and was curious to see how it has evolved.

## Usage

A Makefile is provided to simplify the process of deploying the necessary resources. The following commands can be used:

```bash

# Initialize Terraform and download the necessary providers
terraform init

# To start a k3s cluster and apply the Terraform configuration
make run

```

After running the above commands, a sample Nginx service will be
created, and Nginx Gateway Fabric will be configured to route traffic
to the Nginx service. You can access the Nginx service by navigating to
`http://localhost` in your web browser.
