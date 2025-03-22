##
# This example shows how to deploy FluxCD and Capacitor into a
# Kubernetes cluster using Terraform.
#
# FluxCD is a tool to use Git repositories as sources of truth for
# Kubernetes resources.
#
# Nginx Gateway Fabric is used as a Gateway API implementation to handle
# incoming requests and route them to Capacitor.
#
# Capacitor is a UI for FluxCD
##

## Inputs

## Required Providers

terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    kubectl = {
      source = "alekc/kubectl"
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

### FluxCD

resource "helm_release" "fluxcd" {
  name       = "fluxcd"
  repository = "oci://ghcr.io/fluxcd-community/charts"
  chart      = "flux2"
  version    = "2.14.1" # @see https://github.com/fluxcd-community/helm-charts/releases

  values = [
    # @see https://github.com/fluxcd-community/helm-charts/blob/main/charts/flux2/values.yaml
    yamlencode({

    })
  ]
}

### Capacitor

# Deploy capacitor as a UI for FluxCD

resource "kubectl_manifest" "ocirepository_capacitor" {
  yaml_body = yamlencode({
    apiVersion = "source.toolkit.fluxcd.io/v1beta2"
    kind       = "OCIRepository"
    metadata = {
      name = "capacitor"
    }
    spec = {
      interval = "12h"
      url      = "oci://ghcr.io/gimlet-io/capacitor-manifests"
      ref = {
        semver = ">=0.4.8"
      }
    }
  })
}

resource "kubectl_manifest" "kustomization_capacitor" {
  yaml_body = yamlencode({
    apiVersion = "kustomize.toolkit.fluxcd.io/v1"
    kind       = "Kustomization"
    metadata = {
      name = "capacitor"
    }
    spec = {
      targetNamespace = "default"
      interval        = "1h"
      retryInterval   = "2m"
      timeout         = "5m"
      wait            = true
      prune           = true
      path            = "./"
      sourceRef = {
        kind = "OCIRepository"
        name = "capacitor"
      }
    }
  })
}

### Nginx Gateway Fabric (Gateway API)

# Gateway API CRDs deploy using Helm
# - Required for Nginx Gateway Fabric
# @see https://artifacthub.io/packages/helm/portefaix-hub/gateway-api-crds

resource "helm_release" "gateway-api" {
  name       = "gateway-api"
  repository = "https://charts.portefaix.xyz/"
  chart      = "gateway-api-crds"
  version    = "1.2.0"
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
  version    = "1.5.0"

  values = [
    # @see https://github.com/nginx/nginx-gateway-fabric/blob/main/charts/nginx-gateway-fabric/values.yaml
    yamlencode({
      service = {
        type = "NodePort"
        ports = [
          {
            nodePort   = 30080 # external port
            port       = 80    # service port for internal traffic
            targetPort = 80    # target port within the pod
            protocol   = "TCP"
            name       = "http"
          }
        ]
      }
    })
  ]
}

# Since FluxCD defines a network policy preventing ingress across the
# namespace for all traffic except to a few pods, we need to define a
# network policy to allow all ingress/egress to/from
# nginx-gateway-fabric. There is an opportunity to define a more
# fine-grained policy, but for the purposes of this example, this is
# sufficient.

resource "kubectl_manifest" "networkpolicy_nginx-gateway-fabric" {
  depends_on = [kubectl_manifest.gateway]

  yaml_body = yamlencode({
    apiVersion = "networking.k8s.io/v1"
    kind       = "NetworkPolicy"
    metadata = {
      name = "nginx-gateway-fabric"
    }
    spec = {
      podSelector = {
        matchLabels = {
          "app.kubernetes.io/name" = "nginx-gateway-fabric"
        }
      }
      ingress     = [{}]
      egress      = [{}]
      policyTypes = ["Ingress", "Egress"]
    }
  })
}

### Exposing Resources

# Gateway API requires at least one Gateway to be created to be able to
# route traffic.

resource "kubectl_manifest" "gateway" {
  depends_on = [helm_release.gateway-api]

  # @see https://gateway-api.sigs.k8s.io/
  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name = "nginx-gateway-fabric"
    }
    spec = {
      gatewayClassName = "nginx"
      listeners = [
        {
          name     = "http"
          port     = 80
          protocol = "HTTP"
        }
      ]
    }
  })
}

# We can now create an HTTPRoute to route traffic to the FluxCD service

resource "kubectl_manifest" "httproute_capacitor" {
  depends_on = [kubectl_manifest.gateway]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name = "capacitor"
    }
    spec = {
      parentRefs = [{
        name        = "nginx-gateway-fabric"
        sectionName = "http"
      }]
      rules = [{
        matches = [{
          headers = [{
            name  = "host"
            value = "capacitor.127.0.0.1.nip.io"
          }]
        }]

        backendRefs = [{
          name = "capacitor"
          port = 9000
        }]
      }]
    }
  })
}