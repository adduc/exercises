# Using Victoria Logs in a Kubernetes Cluster

This exercise demonstrates bringing up a Victoria Logs instance in a Kubernetes cluster using the provided Helm chart. It also provisions Vector to collect logs from the cluster and send them to Victoria Logs.

## Context

I have been building out a bare-metal Kubernetes cluster and wanted to set up a centralized logging solution that could handle indexing/querying logs without the overhead of a full ELK stack. I previously evaluated Loki and Victoria Logs using Docker, and found Victoria Logs to fit my needs better due its method of log ingestion and indexing.

## Prerequisites

- Docker Compose
- kubectl
- Terraform or OpenTofu
