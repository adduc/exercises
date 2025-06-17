# Using Kubernetes' Gateway API with Traefik

This exercise demonstrates how traffic can be routed to a service using the Gateway API and Traefik.

## Context

I have previously worked with Nginx Gateway Fabric and its integration with the Gateway API, and was curious to see how other implementations, such as Traefik, handle the same API.

## Usage

A Makefile is provided to simplify the process of deploying the necessary resources. The following commands can be used:

```bash

# Initialize Terraform and download the necessary providers
terraform init

# To start a k3s cluster and apply the Terraform configuration
make run

```

After running the above commands, a sample Nginx service will be
created, and Traefik will be configured to route traffic to it. You can
access the Nginx service by navigating to `http://localhost` in your
web browser.
