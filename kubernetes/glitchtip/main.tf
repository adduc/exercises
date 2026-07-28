##
# This example shows how GlitchTip can be deployed in a Kubernetes cluster
##

## Inputs

variable "glitchtip_secret_key" {
  description = <<-EOT
    A secret key for GlitchTip. Must be 32 characters long.

    You can generate a suitable key using the following command:

        openssl rand -hex 32
  EOT
  type        = string
  sensitive   = true
}

variable "valkey_password" {
  description = "The password for the Valkey database user."
  type        = string
  sensitive   = true
}

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
          SECRET_KEY = var.glitchtip_secret_key
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
          password = var.valkey_password
        }

      }
    })
  ]

  # The Helm chart does not support setting a nodePort directly, so we
  # use `sed` to modify the rendered manifest to include the nodePort
  # setting.
  postrender {
    binary_path = "sed"
    args        = ["s/\\(targetPort: http\\)/\\1\\n      nodePort: 30080/"]
  }

  timeout = 10 * 60 # 10 minutes
}

