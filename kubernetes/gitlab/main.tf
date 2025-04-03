##
# This example shows how to deploy GitLab into a
# Kubernetes cluster using Terraform.
#
# GitLab is a software forge akin to GitHub, with support for Git
# repositories, issue tracking, CI/CD, and more.
##

## Inputs

variable "initial_root_password" {
  type        = string
  description = <<-EOT
    Initial password to set for the root user in GitLab.

    Changing this value after the initial deployment will have no
    effect. You will need to manually change the root password in GitLab
    or reset it via the GitLab Rails console.

    @see https://gitlab.com/gitlab-org/charts/gitlab/-/tags
  EOT
}

variable "gitlab_chart_version" {
  type    = string
  default = "8.10.3"
}

## Required Providers

terraform {
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

### GitLab

# Ensure the Kubernetes namespace for GitLab exists
resource "kubectl_manifest" "gitlab_namespace" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = "gitlab"
    }
  })
}

resource "kubectl_manifest" "initial_root_password" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "gitlab-initial-root-password"
      namespace = "gitlab"
    }
    type = "Opaque"
    data = {
      password = base64encode(var.initial_root_password)
    }
  })

  depends_on = [
    kubectl_manifest.gitlab_namespace
  ]
}

resource "helm_release" "gitlab" {
  name       = "gitlab"
  repository = "https://charts.gitlab.io"
  chart      = "gitlab"
  version    = var.gitlab_chart_version
  namespace  = "gitlab"

  values = [
    # @see https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/values.yaml
    yamlencode({
      global = {
        edition = "ce"

        hosts = {
          domain = "172.17.0.1.nip.io"
          https  = false
        }

        ingress = {
          configureCertmanager = false
          tls = {
            enabled = false
          }
        }

        initialRootPassword = {
          secret = "gitlab-initial-root-password"
          key    = "password"
        }
      }

      certmanager = {
        install = false
      }

      nginx-ingress = {
        controller = {
          service = {
            type = "NodePort"
            nodePorts = {
              http = 30080
            }
            enableHttps = false
          }
        }
      }
    })
  ]

  depends_on = [
    kubectl_manifest.initial_root_password
  ]
}
