##
# This example shows how Cert Manager can be deployed in a Kubernetes
# cluster
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
# Gateway API: a set of resources for managing service networking in
# Kubernetes
#
# @see https://gateway-api.sigs.k8s.io/
# @see https://github.com/wiremind/wiremind-helm-charts
# @see https://artifacthub.io/packages/helm/wiremind/gateway-api-crds
##
resource "helm_release" "gateway-api" {
  name       = "gateway-api"
  repository = "https://wiremind.github.io/wiremind-helm-charts"
  chart      = "gateway-api-crds"
  version    = "1.3.0"
}

##
# Cert Manager: a tool for managing certificates in Kubernetes
#
# @see https://cert-manager.io/
# @see https://github.com/jetstack/cert-manager
##
resource "helm_release" "cert_manager" {
  depends_on = [helm_release.gateway-api]

  name       = "cert-manager"
  repository = "oci://quay.io/jetstack/charts"
  chart      = "cert-manager"
  version    = "v1.18.2"

  # @see https://github.com/cert-manager/cert-manager/blob/master/deploy/charts/cert-manager/values.yaml
  values = [

    yamlencode({
      crds = {
        enabled = true
      }
      config = {
        enableGatewayAPI = true
      }
    })
  ]
}

##
# Nginx Gateway Fabric
#
# Compatibility matrix between Nginx Gateway Fabric and Gateway API versions
# @see https://github.com/nginx/nginx-gateway-fabric/blob/main/README.md#technical-specifications
#
# @see https://docs.nginx.com/nginx-gateway-fabric/installation/installing-ngf/helm/
# @see https://github.com/nginx/nginx-gateway-fabric/pkgs/container/charts%2Fnginx-gateway-fabric
##
resource "helm_release" "nginx-gateway-fabric" {
  depends_on = [helm_release.gateway-api]

  name       = "nginx-gateway-fabric"
  repository = "oci://ghcr.io/nginx/charts"
  chart      = "nginx-gateway-fabric"
  version    = "2.1.1"

  values = [
    # @see https://github.com/nginx/nginx-gateway-fabric/blob/main/charts/nginx-gateway-fabric/values.yaml
    yamlencode({
      nginx = {
        service = {
          type = "NodePort"
          nodePorts = [
            {
              port         = 30080
              listenerPort = 80
            },
            {
              port         = 30443
              listenerPort = 443
            }
          ]
        }
      }
    })
  ]
}

# Example resources to demonstrate the use of Gateway API

resource "kubectl_manifest" "gateway" {
  depends_on = [helm_release.nginx-gateway-fabric]
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
        },
        {
          name     = "https"
          protocol = "HTTPS"
          port     = 443
        }
      ]
    }
  })
}


resource "kubectl_manifest" "httproute" {
  depends_on = [kubectl_manifest.gateway]
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
