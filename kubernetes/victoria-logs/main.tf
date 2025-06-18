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
# VictoriaLogs: a log aggregation and analysis solution
#
# @see https://victoriametrics.com/
# @see https://github.com/VictoriaMetrics/helm-charts
##
resource "helm_release" "victoria-logs" {
  name       = "victoria-logs"
  repository = "https://victoriametrics.github.io/helm-charts/"
  chart      = "victoria-logs-single"
  version    = "0.11.2"

  values = [
    # @see https://github.com/VictoriaMetrics/helm-charts/blob/master/charts/victoria-logs-single/values.yaml
    yamlencode({
      server = {
        service = {
          type     = "NodePort"
          nodePort = 30080
        }
      }
    })
  ]
}

## Example Resources to demonstrate VictoriaLogs usage
