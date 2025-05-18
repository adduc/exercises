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

resource "helm_release" "csi-driver-nfs" {
  name       = "csi-driver-nfs"
  repository = "https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts"
  chart      = "csi-driver-nfs"
  version    = "v4.9.0"
}

resource "kubernetes_manifest" "nfs-storage-class" {
  manifest = {
    apiVersion = "storage.k8s.io/v1"
    kind       = "StorageClass"
    metadata = {
      name = "nfs-csi"
    }
    provisioner = "nfs.csi.k8s.io"
    parameters = {
      server = "nfs-volume-nfs"
      share  = "/"
    }
    reclaimPolicy        = "Delete"
    volumeBindingMode    = "Immediate"
    allowVolumeExpansion = true
    mountOptions         = ["nfsvers=4.1"]
  }
}
