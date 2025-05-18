## Terraform configuration

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.36.0"
    }
  }
}

## Provider configuration

provider "helm" {
  kubernetes {
    config_path = "${path.module}/../kubeconfig.yaml"
  }
}

provider "kubernetes" {
  config_path = "${path.module}/../kubeconfig.yaml"
}

## Resources

resource "kubernetes_manifest" "nfs-pvc" {
  manifest = {
    apiVersion = "v1"
    kind       = "PersistentVolumeClaim"
    metadata = {
      name      = "pvc-nfs-dynamic"
      namespace = "default"
    }
    spec = {
      accessModes = ["ReadWriteMany"]
      resources = {
        requests = {
          storage = "10Gi"
        }
      }
      storageClassName = "nfs-csi"
    }
  }
}

# create sample pod
# use busybox, and a sleep infinite command to keep the pod running
# mount the pvc to /mnt

resource "kubernetes_pod_v1" "nfs-pod" {
  metadata {
    name      = "nfs-pod"
    namespace = "default"
  }
  spec {
    termination_grace_period_seconds = 0
    container {
      name    = "busybox"
      image   = "busybox:latest"
      command = ["sh", "-c", "while true; do sleep 30 & wait $!; done;"]
      volume_mount {
        mount_path = "/mnt"
        name       = "nfs-volume"
      }
    }
    volume {
      name = "nfs-volume"
      persistent_volume_claim {
        claim_name = kubernetes_manifest.nfs-pvc.manifest.metadata.name
      }
    }
  }
}
