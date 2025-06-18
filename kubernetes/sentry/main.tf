##
# This example shows how Sentry can be deployed in a Kubernetes cluster
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
# Sentry: A platform for application monitoring and error tracking
#
# @see https://github.com/getsentry/self-hosted
# @see https://github.com/sentry-kubernetes/charts/tree/develop/charts/sentry
##

resource "helm_release" "sentry" {
  name       = "sentry"
  repository = "https://sentry-kubernetes.github.io/charts"
  chart      = "sentry"
  version    = "26.19.0"

  values = [
    # @see https://github.com/sentry-kubernetes/charts/blob/develop/charts/sentry/values.yaml
    yamlencode({

      config = {
        sentryConfPy = <<-EOT
          # Enable profiling
          SENTRY_FEATURES["organizations:profiling-view"] = True
        EOT
      }

      # @see https://github.com/bitnami/charts/blob/main/bitnami/rabbitmq/values.yaml
      rabbitmq = {
        ulimitNofiles = ""
      }

      # @see https://github.com/bitnami/charts/blob/main/bitnami/nginx/values.yaml
      nginx = {
        service = {
          type = "NodePort"
          nodePorts = {
            http  = 30080
            https = 30443
          }
        }
      }
    })
  ]

  timeout = 10 * 60 # 10 minutes
}

