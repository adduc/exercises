# Running FluxCD and Capacitor on K3s

This example contains the Terraform code to deploy FluxCD and
Capacitor on a K3s cluster.

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

## Deploying FluxCD and Capacitor

```bash
terraform init
terraform apply
```

## Accessing the UI

The UI is available at `https://capacitor.127.0.0.1.nip.io`.


## Resetting the cluster

```bash
docker compose down
sudo rm -rf data/k3s-server ./kubeconfig.yaml
```

