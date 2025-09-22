# Running ddns-updater in Kubernetes

This exercise demonstrates how ddns-updater can be used with webhook
providers to update DNS records for domains using Porkbun for DNS.

## Context

I am in the process of migrating my home lab to Kubernetes. I have a
number of services that I want to expose externally, and I want to use
dynamic DNS to manage the DNS records for these services. I am using
Porkbun as my DNS provider, and I want to use ddns-updater to update
the DNS records automatically when my external IP address changes.

## Notes

Where there's a third-party helm chart available, it appears to rely on
environment variables for configuration. This means that secrets are
exposed in the helm release, which is not ideal. I opted to skip helm
and deploy the application directly using Kubernetes manifests, which
allows me to use Kubernetes secrets to manage sensitive information.
