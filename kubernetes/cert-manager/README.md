# Running Cert-Manager in Kubernetes

This exercise demonstrates how to deploy and manage [cert-manager](https://cert-manager.io/) in a Kubernetes cluster using Terraform. Cert-manager is a powerful tool for automating the management and issuance of TLS certificates from various issuing sources.

## Context

I am in the process of migration my homelab from docker-compose to Kubernetes. As part of this migration, I need a method to serve traffic over HTTPS. Cert-manager appears to be a de facto standard for managing TLS certificates in Kubernetes environments.
