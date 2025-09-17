##
# This example shows how Cloudflare Tunnel can be deployed into a
# Kubernetes cluster to expose services securely to the internet.
##

## Inputs

variable "cloudflare_api_token" {
  description = <<-EOT
    Cloudflare API Token with permissions to manage Tunnels

    Required permissions:
    - Account: Cloudflare Tunnel: Edit
  EOT
  type        = string
  sensitive   = true
}

variable "cloudflare_zone" {
  description = "Cloudflare Zone (domain)"
  type        = string
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
}

variable "cloudflare_tunnel_name" {
  description = "Cloudflare Tunnel Name"
  type        = string
}

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
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
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

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

## Resources


data "cloudflare_zone" "zone" {
  filter = {
    name = var.cloudflare_zone
  }
}


resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  account_id = var.cloudflare_account_id
  name       = var.cloudflare_tunnel_name
  config_src = "cloudflare"
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "tunnel_token" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
}

resource "cloudflare_dns_record" "record" {
  zone_id = data.cloudflare_zone.zone.zone_id
  name    = "tunnel"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  ttl     = 1
  proxied = true
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "tunnel_config" {
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
  account_id = var.cloudflare_account_id
  config = {
    ingress = [
      {
        hostname = "tunnel.${var.cloudflare_zone}"
        service  = "http://nginx-gateway-nginx.default.svc.cluster.local"
      },
      {
        service = "http_status:404"
      }
    ]
  }
}

resource "kubectl_manifest" "secret" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name = "cloudflare-tunnel-secret"
    }
    type = "Opaque"
    data = {
      # Base64 encoded token
      tunnel-token = base64encode(data.cloudflare_zero_trust_tunnel_cloudflared_token.tunnel_token.token)
    }
  })
}


# @see https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/deployment-guides/kubernetes/
resource "kubectl_manifest" "deployment" {
  depends_on = [kubectl_manifest.secret]
  yaml_body = yamlencode({
    apiVersion = "apps/v1"
    kind       = "Deployment"
    metadata = {
      name      = "cloudflared-deployment"
      namespace = "default"
    }
    spec = {
      replicas = 1
      selector = {
        matchLabels = {
          pod = "cloudflared"
        }
      }
      template = {
        metadata = {
          labels = {
            pod = "cloudflared"
          }
        }
        spec = {
          securityContext = {
            sysctls = [
              # Allows ICMP traffic (ping, traceroute) to resources behind cloudflared.
              {
                name  = "net.ipv4.ping_group_range"
                value = "65532 65532"
              }
            ]
          }
          containers = [
            {
              image = "cloudflare/cloudflared:latest"
              name  = "cloudflared"
              env = [
                # Defines an environment variable for the tunnel token.
                {
                  name = "TUNNEL_TOKEN"
                  valueFrom = {
                    secretKeyRef = {
                      name = "cloudflare-tunnel-secret"
                      key  = "tunnel-token"
                    }
                  }
                }
              ]
              command = [
                # Configures tunnel run parameters
                "cloudflared",
                "tunnel",
                "--no-autoupdate",
                "--loglevel",
                "debug",
                "--metrics",
                "0.0.0.0:2000",
                "run"
              ]
              livenessProbe = {
                httpGet = {
                  # Cloudflared has a /ready endpoint which returns 200 if and only if
                  # it has an active connection to Cloudflare's network.
                  path = "/ready"
                  port = 2000
                }
                failureThreshold    = 1
                initialDelaySeconds = 10
                periodSeconds       = 10
              }
            }
          ]
        }
      }
    }
  })
}


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
            }
          ]
        }
      }
    })
  ]
}

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
          name        = "nginx-gateway"
          sectionName = "http"
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
