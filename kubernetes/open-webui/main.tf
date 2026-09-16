##
# This example shows how Open WebUI can be deployed in a Kubernetes
# cluster
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
# Open WebUI: A web interface for large language models
#
# @see https://github.com/open-webui/open-webui
# @see https://github.com/open-webui/helm-charts/tree/main/charts/open-webui
##
resource "helm_release" "open-webui" {
  name       = "open-webui"
  repository = "https://helm.openwebui.com/"
  chart      = "open-webui"
  version    = "6.21.0"

  values = [
    # @see https://github.com/open-webui/helm-charts/blob/main/charts/open-webui/values.yaml
    yamlencode({
      service = {
        type     = "NodePort"
        nodePort = 30080
      }
    })
  ]
}
