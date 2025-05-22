##
# This example shows how to deploy GitLab into a
# Kubernetes cluster using Terraform.
#
# GitLab is a software forge akin to GitHub, with support for Git
# repositories, issue tracking, CI/CD, and more.
##

## Inputs

variable "gitlab_agent_access_token" { type = string }

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
    config_path = "${path.module}/../kubeconfig.yaml"
  }
}

provider "kubectl" {
  config_path = "${path.module}/../kubeconfig.yaml"
}

## Resources

### GitLab

# Ensure the Kubernetes namespace for GitLab exists
resource "kubectl_manifest" "gitlab_namespace" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = "example-project-agent"
    }
  })
}

resource "helm_release" "gitlab" {
  name       = "example-project-agent"
  repository = "https://charts.gitlab.io"
  chart      = "gitlab-agent"
  version    = "v2.15.0"
  namespace  = yamldecode(kubectl_manifest.gitlab_namespace.yaml_body)["metadata"]["name"]

  values = [
    # @see https://gitlab.com/gitlab-org/charts/gitlab-agent
    yamlencode({
      image = {
        tag = "v18.0.1"
      }

      config = {
        token      = var.gitlab_agent_access_token
        kasAddress = "wss://kas.gitlab.172.17.0.1.nip.io"
      }
    })
  ]
}
