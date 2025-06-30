##
# This example shows how Victoria Metrics and related services can be
# deployed in a Kubernetes cluster
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
# VictoriaMetrics: a monitoring solution for time series data
# (better performing and API-compatible with Prometheus)
#
# @see https://victoriametrics.com/
# @see https://github.com/VictoriaMetrics/helm-charts
##
resource "helm_release" "victoria-metrics" {
  name       = "victoria-metrics"
  repository = "https://victoriametrics.github.io/helm-charts/"
  chart      = "victoria-metrics-single"
  version    = "0.21.0"

  values = [
    # @see https://github.com/VictoriaMetrics/helm-charts/blob/master/charts/victoria-metrics-single/values.yaml
    yamlencode({
      server = {
        service = {
          type     = "NodePort"
          nodePort = 30080
        }
        scrape = {
          enabled = true
          config = {
            scrape_configs = [
              {
                job_name = "victoria-metrics"
                static_configs = [
                  {
                    targets = ["localhost:8428"]
                  }
                ]
              },
              {
                job_name = "node-exporter"
                kubernetes_sd_configs = [
                  {
                    role = "endpoints"
                  }
                ]
                relabel_configs = [
                  {
                    source_labels = ["__meta_kubernetes_endpoints_name"]
                    regex         = "node-exporter-prometheus-node-exporter"
                    action        = "keep"
                  }
                ]
              }
            ]
          }
        }
      }
    })
  ]
}

## Example Resources to demonstrate VictoriaMetrics usage

##
# Node Exporter
# @see https://github.com/prometheus/node_exporter
# @see https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-node-exporter
##

resource "helm_release" "node-exporter" {
  name       = "node-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-node-exporter"
  version    = "4.47.0"

  values = [
    # @see https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus-node-exporter/values.yaml
  ]
}
