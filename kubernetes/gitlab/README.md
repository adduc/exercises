# Provisioning GitLab using Helm (through Terraform)

This exercise shows how GitLab can be provisioned using Helm on a Kubernetes cluster. This approach allows for greater configurability compared to the traditional omnibus docker image.

## Context

Years ago, I would routinely provision GitLab for local development and testing using their omnibus docker image. When I had a need to provision a GitLab instance for a project recently, I found that some application settings were not configurable via the omnibus image's environment variables. After some research, I found that GitLab's helm chart appeared to offer more flexibility and configurability, including the ability to specify custom application settings.

## Prerequisites

- Docker Compose
- Terraform

## Deploying the cluster

```bash
docker compose up -d
```

## Accessing the cluster

After deploying the cluster, a kubeconfig.yaml file is created in the
root of the repository. This file can be used to access the cluster.

```bash
kubectl --kubeconfig kubeconfig.yaml get nodes
```

## Deploying GitLab

```bash
terraform init
terraform apply

# Set dark theme for root user in GitLab (optional)
make gitlab/set-root-theme
```

## Accessing GitLab

Once GitLab has been deployed, you can access it via the following URL:

```
http://gitlab.172.17.0.1.nip.io
```

## Resetting the cluster

A Makefile has been provided to simplify the process of resetting the cluster. This will kill the k3s cluster and delete all of its data.

```bash
make reset
```
