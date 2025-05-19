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

resource "kubernetes_manifest" "smb-pvc" {
  manifest = {
    apiVersion = "v1"
    kind       = "PersistentVolumeClaim"
    metadata = {
      name      = "pvc-smb-dynamic"
      namespace = "default"
    }
    spec = {
      accessModes = ["ReadWriteMany"]
      resources = {
        requests = {
          storage = "10Gi"
        }
      }
      storageClassName = "smb-csi"
    }
  }
}

# create sample pod
# use busybox, and a sleep infinite command to keep the pod running
# mount the pvc to /mnt

resource "kubernetes_pod_v1" "smb-pod" {
  metadata {
    name      = "smb-pod"
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
        name       = "smb-volume"
      }
    }
    volume {
      name = "smb-volume"
      persistent_volume_claim {
        claim_name = kubernetes_manifest.smb-pvc.manifest.metadata.name
      }
    }
  }
}
