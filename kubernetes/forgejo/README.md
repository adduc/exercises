# Deploying Forgejo on K3s using Helm

This exercise demonstrates how to deploy Forgejo (a lightweight, self-hosted Git service) on a K3s cluster using Helm and Terraform.

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

## Configuration

Copy the example configuration file and customize the Forgejo admin account settings:

```bash
cp terraform.dist.tfvars terraform.tfvars
```

Edit `terraform.tfvars` to set:
- `forgejo_username` - Username for the Forgejo admin account
- `forgejo_password` - Password for the Forgejo admin account  
- `forgejo_email` - Email for the Forgejo admin account

## Deploying Forgejo

```bash
terraform init
terraform apply
```

## Accessing Forgejo

Once Forgejo has been deployed, you can access it via the following URL:

```
http://localhost/
```

SSH access is available on port 30022:

```bash
git clone ssh://git@localhost:30022/username/repository.git
```

## Using the Makefile

A Makefile is provided to simplify common operations:

```bash
# Start cluster and deploy Forgejo in one command
make run

# Start just the cluster
make start

# Stop the cluster
make stop

# Reset everything (stop cluster and remove all data)
make reset
```

## Resetting the cluster

To completely reset the cluster and remove all data:

```bash
make reset
```