##
# ddns-updater module: Deploys ddns-updater into a Kubernetes cluster.
#
# ddns-updater updates DNS records based on the current IP address of
# the host.
##

## Inputs

variable "settings" {
  description = "The DDNS settings"
  type        = list(map(string))
}

variable "resolver_address" {
  description = "The DNS resolver address to use"
  type        = string
  default     = "1.1.1.1:53"
}

variable "service_type" {
  description = "The type of Kubernetes Service to create"
  type        = string
  default     = "ClusterIP"
}

variable "node_port" {
  description = "The node port to use if service_type is NodePort"
  type        = number
  default     = 30080
}

variable "storage_class_name" {
  description = "The storage class name to use for the PersistentVolumeClaim"
  type        = string
  default     = null
}

## Required Providers

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    kubectl = {
      source = "alekc/kubectl"
    }
  }
}

## Resources

# secret
resource "kubectl_manifest" "ddns_updater_secret" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name = "ddns-updater-secret"
    }
    type = "Opaque"
    data = {
      config = base64encode(jsonencode({
        settings = var.settings
      }))
    }
  })
}

# persistent volume claim
resource "kubectl_manifest" "ddns_updater_pvc" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "PersistentVolumeClaim"
    metadata = {
      name = "ddns-updater-pvc"
    }
    spec = merge(
      {
        accessModes = ["ReadWriteOnce"]
        resources = {
          requests = {
            storage = "10Mi"
          }
        }
      },
      var.storage_class_name != null ? {
        storageClassName = var.storage_class_name
      } : {}
    )
  })
}

# deployment

resource "kubectl_manifest" "ddns_updater_deployment" {
  depends_on = [
    kubectl_manifest.ddns_updater_secret,
    kubectl_manifest.ddns_updater_pvc
  ]

  yaml_body = yamlencode({
    apiVersion = "apps/v1"
    kind       = "Deployment"
    metadata = {
      name = "ddns-updater"
    }
    spec = {
      replicas = 1
      selector = {
        matchLabels = {
          app = "ddns-updater"
        }
      }
      template = {
        metadata = {
          labels = {
            app = "ddns-updater"
          }
        }
        spec = {
          containers = [
            {
              name  = "ddns-updater"
              image = "qmcgaw/ddns-updater:v2"
              ports = [
                {
                  containerPort = 8000
                  protocol      = "TCP"
                }
              ]
              volumeMounts = [
                {
                  name      = "data"
                  mountPath = "/updater/data"
                },
                {
                  name      = "ddns-updater-secret"
                  mountPath = "/updater/data/config.json"
                  subPath   = "config"
                }
              ]
              env = [
                {
                  name  = "RESOLVER_ADDRESS"
                  value = var.resolver_address
                }
              ]
            }
          ]
          volumes = [
            {
              name = "data"
              persistentVolumeClaim = {
                claimName = "ddns-updater-pvc"
              }
            },
            {
              name = "ddns-updater-secret"
              secret = {
                secretName = "ddns-updater-secret"
              }
            }
          ]
        }
      }
    }
  })
}

resource "kubectl_manifest" "ddns_updater_service" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      name = "ddns-updater"
    }
    spec = {
      type = var.service_type
      selector = {
        app = "ddns-updater"
      }
      ports = [
        {
          port       = 80
          targetPort = 8000
          nodePort   = var.service_type == "NodePort" ? var.node_port : null
          protocol   = "TCP"
        }
      ]
    }
  })
}
