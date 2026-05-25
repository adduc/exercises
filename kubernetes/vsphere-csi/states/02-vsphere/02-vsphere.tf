# @see https://kubernetes-sigs.github.io/vsphere-csi-driver/

## Terraform Configuration

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.36"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

## Provider Configuration

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

## Inputs

variable "kubeconfig_path" {
  description = "Path to the kubeconfig file for the K3s cluster."
  type        = string
  default     = "../../k3s_kubeconfig.yaml"
}

variable "vsphere" {
  description = "vSphere credentials and cluster topology used to configure the CSI driver."
  type = object({
    user                 = string
    password             = string
    vsphere_server       = string
    allow_unverified_ssl = bool
    datacenter           = string
    datastore_url        = string
    cluster_id           = string
  })
}

## Resources / Modules / Data Sources

module "vsphere_csi_driver" {
  source  = "../../modules/vsphere_csi_driver"
  vsphere = var.vsphere
}

## Demo

resource "kubernetes_persistent_volume_claim" "demo" {
  depends_on = [module.vsphere_csi_driver]

  metadata {
    name      = "vsphere-csi-demo"
    namespace = "default"
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = module.vsphere_csi_driver.storage_class_name
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }

  # WaitForFirstConsumer: PVC stays Pending until a pod is scheduled.
  # Setting false avoids a deadlock where Terraform waits for binding
  # before creating the pod that would trigger it.
  wait_until_bound = false

  timeouts {
    create = "5m"
  }
}

resource "kubernetes_pod" "demo" {
  depends_on = [kubernetes_persistent_volume_claim.demo]

  metadata {
    name      = "vsphere-csi-demo"
    namespace = "default"
  }

  spec {
    container {
      name    = "demo"
      image   = "busybox"
      command = ["sh", "-c", "echo 'vSphere CSI works' > /data/hello.txt && sleep 3600"]

      volume_mount {
        name       = "data"
        mount_path = "/data"
      }
    }

    volume {
      name = "data"
      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim.demo.metadata[0].name
      }
    }
  }
}
