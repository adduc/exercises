# Using Cloudflare Tunnel to expose services in Kubernetes

This example shows how Cloudflare Tunnel can be deployed into a Kubernetes cluster to expose services securely to the internet.

## Context

I am in the process of migrating my home lab to Kubernetes. I have a number of services that I want to expose to the internet without directly exposing my home IP address. Cloudflare Tunnel provides a secure way to do this by creating an outbound connection from my Kubernetes cluster to Cloudflare's network.
