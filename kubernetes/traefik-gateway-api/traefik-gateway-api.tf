##
# This example shows how Traefik can be deployed to handle Gateway API
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

# Traefik: an application proxy
#
# The Traefik helm chart includes the Gateway API spec CRDs; there's no
# need to install them separately.
#
# @see https://doc.traefik.io/traefik/
# @see https://github.com/traefik/traefik-helm-chart
resource "helm_release" "traefik" {
  name       = "traefik"
  repository = "oci://ghcr.io/traefik/helm"
  chart      = "traefik"
  version    = "36.1.0"

  # @see https://github.com/traefik/traefik-helm-chart/blob/master/traefik/values.yaml
  values = [
    yamlencode({
      service = {
        type = "NodePort"
      }

      ports = {
        web = {
          nodePort = 30080
        }
      }

      providers = {
        kubernetesGateway = {
          enabled = true
        }
      }
    })
  ]
}

# Example resources to demonstrate the use of Gateway API

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
          name = "traefik-gateway"
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
