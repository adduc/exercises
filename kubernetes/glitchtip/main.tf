##
# This example shows how GlitchTip can be deployed in a Kubernetes cluster
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
# GlitchTip: A self-hosted error tracking and monitoring solution
#
# @see https://glitchtip.com/
# @see https://gitlab.com/glitchtip/glitchtip-helm-chart/-/tree/master/charts/glitchtip
##

resource "helm_release" "glitchtip" {
  name       = "glitchtip"
  repository = "https://gitlab.com/api/v4/projects/16325141/packages/helm/stable"
  chart      = "glitchtip"
  version    = "6.0.0"

  values = [
    # @see https://gitlab.com/glitchtip/glitchtip-helm-chart/-/blob/master/charts/glitchtip/values.yaml
    yamlencode({

      env = {
        secret = {
          # openssl rand -hex 32
          SECRET_KEY = "35357aef3c1f75c8b8a417425ae88dc932b274febd358e14fd9d0c993379a243"
        }
      }

      postgresql = {
        enabled = true
      }

      web = {
        service = {
          type = "NodePort"
        }
      }

      # @see https://artifacthub.io/packages/helm/bitnami/valkey
      valkey = {
        auth = {
          enabled  = true
          password = "2c4c903227b0c83c029d005cd7be8fda080d6ce9fe50c33ea4f6261dc2e8f6b9"
        }

      }
    })
  ]

  postrender {
    binary_path = "sed"
    args        = ["s/\\(targetPort: http\\)/\\1\\n      nodePort: 30080/"]
  }

  timeout = 10 * 60 # 10 minutes
}

