# Using Local Path Provisioner for storage in Kubernetes

This example shows how Local Path Provisioner can be used to
dynamically provision volumes using local storage in a Kubernetes
cluster.

## Context

I recently worked on a project that was deployed to a self-hosted
Kubernetes cluster. Prior to the project, there had been no need for
persistent storage, and the cluster was set up without any storage
provisioners. Without an NFS server or other networked storage available, I wanted to evaluate Rancher's Local Path Provisioner to dynamically provision local storage.

## Usage

A docker compose file is provided to set up a single-node k3s cluster
with k3s' built-in local path provisioned purposefully disabled.

A terraform file is provided to deploy the Local Path Provisioner to
the cluster to emulate how it would be setup in a self-hosted cluster.
