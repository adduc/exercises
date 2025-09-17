##
# This example shows how Cert Manager can be deployed in a Kubernetes
# cluster
##

## Inputs

variable "porkbun_api_key" {
  description = "Porkbun API Key"
  type        = string
  sensitive   = true
}

variable "porkbun_secret_key" {
  description = "Porkbun Secret Key"
  type        = string
  sensitive   = true
}

variable "group_name" {
  description = "The group name for the Porkbun webhook"
  type        = string
}

variable "email" {
  description = "Email address for ACME registration"
  type        = string
}

variable "porkbun_domain" {
  description = "The Porkbun domain to manage"
  type        = string
}

variable "certificate_dns_names" {
  description = "The DNS names to include in the certificate"
  type        = list(string)
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

##
# Porkbun Webhook for Cert Manager
#
# @see https://github.com/mdonoughe/porkbun-webhook
##
resource "helm_release" "webhook-porkbun" {
  depends_on = [helm_release.cert_manager]

  name  = "webhook-porkbun"
  chart = "https://github.com/mdonoughe/porkbun-webhook/releases/download/porkbun-webhook-0.1.5/porkbun-webhook-0.1.5.tgz"

  # @see https://github.com/mdonoughe/porkbun-webhook/blob/main/deploy/porkbun-webhook/values.yaml
  values = [
    yamlencode({
      groupName = var.group_name

      certManager = {
        namespace = "default"
      }
    })
  ]
}

resource "kubectl_manifest" "porkbun_webhook_secret_reader_role" {
  yaml_body = yamlencode({
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "Role"
    metadata = {
      name      = "webhook-porkbun-secret-reader"
      namespace = "default"
    }
    rules = [
      {
        apiGroups     = [""]
        resources     = ["secrets"]
        verbs         = ["get"]
        resourceNames = ["porkbun-key"]
      }
    ]
  })
}

resource "kubectl_manifest" "porkbun_webhook_secret_reader_binding" {
  yaml_body = yamlencode({
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "RoleBinding"
    metadata = {
      name      = "webhook-porkbun-secret-reader-binding"
      namespace = "default"
    }
    roleRef = {
      apiGroup = "rbac.authorization.k8s.io"
      kind     = "Role"
      name     = "webhook-porkbun-secret-reader"
    }
    subjects = [
      {
        kind      = "ServiceAccount"
        name      = "webhook-porkbun-porkbun-webhook"
        namespace = "default"
      }
    ]
  })
}


resource "kubectl_manifest" "porkbun_secret" {
  depends_on = [helm_release.webhook-porkbun]
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name = "porkbun-key"
    }
    type = "Opaque"
    data = {
      "api-key"    = base64encode(var.porkbun_api_key)
      "secret-key" = base64encode(var.porkbun_secret_key)
    }
  })
}

# @see https://cert-manager.io/docs/configuration/acme/
resource "kubectl_manifest" "issuer" {
  depends_on = [helm_release.cert_manager, kubectl_manifest.porkbun_secret]
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name = "issuer"
    }
    spec = {
      acme = {
        email  = var.email
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "example-issuer-account-key"
        }
        solvers = [
          {
            selector = {
              dnsZones = [var.porkbun_domain]
            }
            dns01 = {
              webhook = {
                groupName  = var.group_name
                solverName = "porkbun"
                config = {
                  apiKeySecretRef = {
                    name = "porkbun-key"
                    key  = "api-key"
                  }
                  secretKeySecretRef = {
                    name = "porkbun-key"
                    key  = "secret-key"
                  }
                }
              }
            }
          }
        ]
      }
    }
  })
}

# certificate

resource "kubectl_manifest" "certificate" {
  depends_on = [kubectl_manifest.issuer]
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name = "example-cert"
    }
    spec = {
      secretName = "example-cert-tls"
      dnsNames   = var.certificate_dns_names
      issuerRef = {
        name = "issuer"
        kind = "Issuer"
      }
    }
  })
}

resource "kubectl_manifest" "gateway" {
  depends_on = [helm_release.nginx-gateway-fabric, kubectl_manifest.certificate]
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
          tls = {
            mode = "Terminate"
            certificateRefs = [
              {
                name = "example-cert-tls"
              }
            ]
          }
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
        },
        {
          name        = "nginx-gateway"
          sectionName = "https"
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
