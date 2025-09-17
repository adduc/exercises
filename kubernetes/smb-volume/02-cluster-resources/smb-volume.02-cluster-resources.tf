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

resource "helm_release" "csi-driver-smb" {
  name       = "csi-driver-smb"
  repository = "https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts"
  chart      = "csi-driver-smb"
  version    = "v1.18.0"
}

resource "kubernetes_manifest" "smb-secret" {
  manifest = {
    apiVersion = "v1"
    kind       = "Secret"
    type       = "Opaque"
    metadata = {
      name      = "smb-secret"
      namespace = "default"
    }
    data = {
      "username" = base64encode("admin")
      "password" = base64encode("admin")
    }
  }
}

resource "kubernetes_manifest" "smb-storage-class" {
  depends_on = [
    kubernetes_manifest.smb-secret,
    helm_release.csi-driver-smb
  ]
  manifest = {
    apiVersion = "storage.k8s.io/v1"
    kind       = "StorageClass"
    metadata = {
      name = "smb-csi"
    }
    provisioner = "smb.csi.k8s.io"
    parameters = {
      source                                            = "//smb-volume-smb/data"
      "csi.storage.k8s.io/provisioner-secret-name"      = kubernetes_manifest.smb-secret.manifest.metadata.name
      "csi.storage.k8s.io/provisioner-secret-namespace" = kubernetes_manifest.smb-secret.manifest.metadata.namespace
      "csi.storage.k8s.io/node-stage-secret-name"       = kubernetes_manifest.smb-secret.manifest.metadata.name
      "csi.storage.k8s.io/node-stage-secret-namespace"  = kubernetes_manifest.smb-secret.manifest.metadata.namespace

    }
    reclaimPolicy        = "Delete"
    volumeBindingMode    = "Immediate"
    allowVolumeExpansion = true
    mountOptions = [
      "dir_mode=0777",
      "file_mode=0777",
      "uid=1001",
      "gid=1001",
      "actimeo=30", # set the cache timeout to 30 seconds
      "nobrl",      # disable byte range locking
      "mfsymlinks", # support symlinks
      "cache=strict",
      "noserverino", # required to prevent data corruption
    ]
  }
}
