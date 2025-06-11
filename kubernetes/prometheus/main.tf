##
# This example shows how Local Path Provisioner can be used to
# dynamically provision volumes using local storage in a Kubernetes
# cluster.
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


# Around 760mb memory used

# resource "helm_release" "prometheus" {
#   name             = "prometheus"
#   repository       = "https://prometheus-community.github.io/helm-charts"
#   chart            = "prometheus"
#   version          = "27.20.0"
#   namespace        = "metrics"
#   create_namespace = true

#   # @see https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus/Chart.yaml
#   values = [
#   ]
# }



# Around 1.4gb memory used, some alerts are firing that need to be
# investigated due to k3s' default configuration

resource "helm_release" "kube-prometheus-stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "73.2.0"
  namespace        = "metrics"
  create_namespace = true

  # @see https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus/Chart.yaml
  values = [
  ]
}
