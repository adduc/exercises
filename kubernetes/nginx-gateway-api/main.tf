##
# This example shows how Nginx can be deployed to handle Gateway API
# resources in a Kubernetes cluster.
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

# Gateway API CRDs deploy using Helm
# - Required for Nginx Gateway Fabric
# @see https://artifacthub.io/packages/helm/portefaix-hub/gateway-api-crds

resource "helm_release" "gateway-api" {
  name       = "gateway-api"
  repository = "https://charts.portefaix.xyz/"
  chart      = "gateway-api-crds"
  version    = "1.2.1"
}

# Nginx Gateway Fabric deploy using Helm
# @see https://docs.nginx.com/nginx-gateway-fabric/installation/installing-ngf/helm/
# @see https://github.com/nginx/nginx-gateway-fabric/pkgs/container/charts%2Fnginx-gateway-fabric
# Compatibility matrix between Nginx Gateway Fabric and Gateway API versions
# @see https://github.com/nginx/nginx-gateway-fabric/blob/v1.5.1/README.md#technical-specifications

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

# Example resources to demonstrate the use of Gateway API

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
}


resource "kubectl_manifest" "httproute" {
  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name = "example-httproute"
    }
    spec = {
      parentRefs = [
        {
          name = "nginx-gateway"
        }
      ]
      rules = [
        {
          matches = [
            {
              path = {
                value = "/"
              }
            }
          ]
          backendRefs = [
            {
              name = "example-service"
              port = 80
            }
          ]
        }
      ]
    }
  })
}

resource "kubectl_manifest" "service" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      name = "example-service"
    }
    spec = {
      selector = {
        app = "example-app"
      }
      ports = [
        {
          protocol   = "TCP"
          port       = 80
          targetPort = 80
        }
      ]
    }
  })
}

resource "kubectl_manifest" "pod" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Pod"
    metadata = {
      name = "example-app"
      labels = {
        app = "example-app"
      }
    }
    spec = {
      containers = [
        {
          name  = "example-container"
          image = "nginx:latest"
          ports = [
            {
              containerPort = 80
            }
          ]
        }
      ]
    }
  })
}
