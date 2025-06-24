##
# This example shows a "metric stack" deployment on Kubernetes using Helm.
#
# It deploys Nginx Gateway Fabric, Prometheus, Node Exporter,
# Blackbox Exporter, and Grafana.
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
# Gateway API CRDs deploy using Helm
# - Required for Nginx Gateway Fabric
# @see https://artifacthub.io/packages/helm/portefaix-hub/gateway-api-crds
##
resource "helm_release" "gateway-api" {
  name       = "gateway-api"
  repository = "https://charts.portefaix.xyz/"
  chart      = "gateway-api-crds"
  version    = "1.2.1"
}

##
# Nginx Gateway Fabric deploy using Helm
# @see https://docs.nginx.com/nginx-gateway-fabric/installation/installing-ngf/helm/
# @see https://github.com/nginx/nginx-gateway-fabric/pkgs/container/charts%2Fnginx-gateway-fabric
# Compatibility matrix between Nginx Gateway Fabric and Gateway API versions
# @see https://github.com/nginx/nginx-gateway-fabric/blob/v1.5.1/README.md#technical-specifications
##
resource "helm_release" "nginx-gateway-fabric" {
  depends_on = [helm_release.gateway-api]
  name       = "nginx-gateway-fabric"
  repository = "oci://ghcr.io/nginx/charts"
  chart      = "nginx-gateway-fabric"
  version    = "2.0.1"

  values = [
    # @see https://github.com/nginx/nginx-gateway-fabric/blob/main/charts/nginx-gateway-fabric/values.yaml
    yamlencode({
      nginx = {
        service = {
          type = "NodePort"

          nodePorts = [
            {
              port         = 30080 # external port
              listenerPort = 80    # service port for internal traffic
            }
          ]
        }
      }
    })
  ]
}

##
# Default gateway for our services
#
# This gateway resource represents traffic to Nginx Gateway Fabric
# on port 80. It will be used by http routes to inform Nginx Gateway
# Fabric how and where to route traffic.
##
resource "kubectl_manifest" "gateway" {
  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name = "nginx-gateway"
    }
    spec = {
      gatewayClassName = "nginx"
      listeners = [
        {
          name     = "http"
          protocol = "HTTP"
          port     = 80
        }
      ]
    }
  })

  depends_on = [
    helm_release.gateway-api
  ]
}

##
# Prometheus: A powerful open-source monitoring and alerting toolkit.
# @see https://prometheus.io/
# @see https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus
##

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = "27.20.0"

  # @see https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus/values.yaml
  values = [
    yamlencode({
      prometheus-pushgateway = {
        enabled = false
      }

      kube-state-metrics = {
        enabled = false
      }
    })
  ]
}

##
# Http Route for Prometheus
#
# This route will direct traffic to the Prometheus server based on the
# host header.
##
resource "kubectl_manifest" "http_route_prometheus" {
  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name = "prometheus"
    }
    spec = {
      parentRefs = [{ name = "nginx-gateway" }]
      rules = [{
        matches = [{
          headers = [{
            name  = "Host"
            type  = "RegularExpression"
            value = "prometheus\\..+"
          }]
        }]
        backendRefs = [{
          name = "prometheus-server"
          port = 80
        }]
      }]
    }
  })

  depends_on = [
    helm_release.gateway-api
  ]
}

##
# Http Route for Alertmanager (installed with the Prometheus Helm chart)
#
# This route will direct traffic to the Alertmanager server based on the
# host header.
##
resource "kubectl_manifest" "http_route_alertmanager" {
  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name = "alertmanager"
    }
    spec = {
      parentRefs = [{ name = "nginx-gateway" }]
      rules = [{
        matches = [{
          headers = [{
            name  = "Host"
            type  = "RegularExpression"
            value = "alertmanager\\..+"
          }]
        }]
        backendRefs = [{
          name = "prometheus-alertmanager"
          port = 9093
        }]
      }]
    }
  })

  depends_on = [
    helm_release.gateway-api
  ]
}


##
# Grafana: visualization platform for observability and data analytics
#
# @see https://grafana.com/
# @see https://github.com/grafana/helm-charts/tree/main/charts/grafana
##
resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts/"
  chart      = "grafana"
  version    = "9.2.7"

  values = [
    # @see https://github.com/grafana/helm-charts/blob/main/charts/grafana/values.yaml
    yamlencode({
      adminUser     = "admin"
      adminPassword = "admin"
    })
  ]
}

##
# Http Route for Grafana
#
# This route will direct traffic to the Grafana server based on the
# host header.
##
resource "kubectl_manifest" "http_route_grafana" {
  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name = "grafana"
    }
    spec = {
      parentRefs = [{ name = "nginx-gateway" }]
      rules = [{
        matches = [{
          headers = [{
            name  = "Host"
            type  = "RegularExpression"
            value = "grafana\\..+"
          }]
        }]
        backendRefs = [{
          name = "grafana"
          port = 80
        }]
      }]
    }
  })

  depends_on = [
    helm_release.gateway-api
  ]
}
