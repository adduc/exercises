# Managing K3s with Docker and kubectl Terraform Provider

This exercise demonstrates how to deploy and manage a K3s Kubernetes cluster using the Docker Terraform provider and subsequently deploy Kubernetes resources using the kubectl Terraform provider.

## Context

This example showcases a complete Terraform workflow that:
1. Creates a K3s cluster in a Docker container
2. Extracts the kubeconfig from the running container
3. Uses the kubectl provider to deploy Kubernetes resources directly from Terraform

The approach demonstrates how Terraform can manage both the infrastructure (K3s cluster) and the applications (Kubernetes deployments) in a single configuration.

## Prerequisites

- Docker
- Terraform

## Infrastructure Setup

The Terraform configuration creates:
- A K3s cluster running in a Docker container
- An example nginx deployment to demonstrate kubectl provider functionality

```bash
terraform init
terraform apply
```

## Accessing the Cluster

The K3s API server is exposed on `localhost:6443`. The kubeconfig is automatically extracted from the running container and used by the kubectl provider.

You can also access the cluster manually:

```bash
# Copy kubeconfig from the container
docker cp k3s:/etc/rancher/k3s/k3s.yaml ./kubeconfig.yaml

# Update the server address in kubeconfig
sed -i 's/127.0.0.1:6443/localhost:6443/g' kubeconfig.yaml

# Use kubectl with the extracted config
kubectl --kubeconfig kubeconfig.yaml get nodes
kubectl --kubeconfig kubeconfig.yaml get deployments
```

## Key Features

- **Integrated Workflow**: Terraform manages both cluster creation and application deployment
- **Automatic Configuration**: Kubeconfig is extracted and used automatically
- **Custom Docker Provider**: Uses a custom Docker provider (`adduc/docker`) for file extraction capabilities
- **Health Checks**: Container includes health checks to ensure cluster readiness

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

This will remove the K3s container and all associated data.

## Technical Notes

- The configuration uses a custom Docker provider (`adduc/docker`) for advanced file operations
- K3s is configured with minimal components (Traefik, ServiceLB, and metrics-server disabled)
- The cluster data is persisted in a local `data/k3s-server` directory
- Mount sharing is configured to avoid kubelet mount issues in containerized environments
