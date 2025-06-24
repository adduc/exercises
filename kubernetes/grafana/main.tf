##
# This example shows how Grafana can be deployed in a Kubernetes cluster
##

## Inputs

## Required Providers

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.0"
    }
  }
}

## Provider Configuration

provider "helm" {
  kubernetes {
    config_path = "${path.module}/kubeconfig.yaml"
  }
}

provider "kubectl" {
  config_path = "${path.module}/kubeconfig.yaml"
}

## Resources

##
# Grafana: visualization platform for observability and data analytics
#
# @see https://grafana.com/
# @see https://github.com/grafana/helm-charts/tree/main/charts/grafana
##
resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts/"
  chart      = "grafana"
  version    = "9.2.7"

  values = [
    # @see https://github.com/grafana/helm-charts/blob/main/charts/grafana/values.yaml
    yamlencode({
      service = {
        type     = "NodePort"
        nodePort = 30080
      }
      adminUser     = "admin"
      adminPassword = "admin"
    })
  ]
}
