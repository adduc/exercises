##
# This example shows how Forgejo can be deployed in a Kubernetes cluster
##

## Inputs

variable "forgejo_username" {
  description = "Username for the Forgejo admin account"
  type        = string
}

variable "forgejo_password" {
  description = "Password for the Forgejo admin account"
  type        = string
  sensitive   = true
}

variable "forgejo_email" {
  description = "Email for the Forgejo admin account"
  type        = string
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
# Forgejo: A lightweight, self-hosted Git service
#
# @see https://forgejo.org/
# @see https://code.forgejo.org/forgejo-helm/forgejo-helm
##
resource "helm_release" "forgejo" {
  name       = "forgejo"
  repository = "oci://code.forgejo.org/forgejo-helm"
  chart      = "forgejo"
  version    = "12.5.4"

  values = [
    # @see https://code.forgejo.org/forgejo-helm/forgejo-helm/src/branch/main/values.yaml
    yamlencode({
      service = {
        http = {
          type     = "NodePort"
          nodePort = 30080
        }
        ssh = {
          type     = "NodePort"
          nodePort = 30022
        }
      }

      strategy = {
        # Forgejo does not support rolling updates when using SQLite
        type = "Recreate"
      }

      "redis-cluster" = {
        enabled = false
      }

      "postgresql-ha" = {
        enabled = false
      }

      gitea = {
        admin = {
          username = var.forgejo_username
          password = var.forgejo_password
          email    = var.forgejo_email
        }
        config = {
          database = {
            db_type = "sqlite3"
            path    = "/data/forgejo.db"
          }
          server = {
            domain     = "localhost"
            root_url   = "http://localhost/"
            protocol   = "http"
            ssh_domain = "localhost"
            ssh_port   = 30022
          }
        }
      }
    })
  ]
}
