# Running Cert-Manager in Kubernetes

This exercise demonstrates how cert-manager can be used with webhook providers to issue TLS certificates for domains using Porkbun for DNS.

## Context

I am in the process of migration my homelab from docker-compose to Kubernetes. As part of this migration, I need a method to serve traffic over HTTPS. Cert-manager appears to be a de facto standard for managing TLS certificates in Kubernetes environments.
