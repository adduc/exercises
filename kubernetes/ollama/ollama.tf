##
# This example shows how Ollama can be deployed in a Kubernetes cluster
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
# Ollama: a tool for running large language models
#
# @see https://ollama.com/
# @see https://github.com/otwld/ollama-helm
##
resource "helm_release" "ollama" {
  name       = "ollama"
  repository = "https://helm.otwld.com/"
  chart      = "ollama"
  version    = "1.19.0"

  values = [
    # @see https://github.com/otwld/ollama-helm/blob/main/values.yaml
    yamlencode({
      service = {
        type     = "NodePort"
        nodePort = 30080
      }

      ollama = {
        models = {
          pull = [
            "qwen3:0.6b"
          ]
        }
      }
    })
  ]
}
