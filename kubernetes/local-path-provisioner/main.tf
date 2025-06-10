##
# This example shows how Local Path Provisioner can be used to
# dynamically provision volumes using local storage in a Kubernetes
# cluster.
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

# @see https://github.com/rancher/local-path-provisioner
# @see https://github.com/containeroo/helm-charts
resource "helm_release" "local_path_provisioner" {
  name       = "local-path-provisioner"
  repository = "https://charts.containeroo.ch"
  chart      = "local-path-provisioner"
  version    = "0.0.32"
  namespace  = "kube-system"

  # @see https://github.com/rancher/local-path-provisioner/blob/master/deploy/chart/local-path-provisioner/values.yaml
  values = [
  ]
}

# To demonstrate the Local Path Provisioner, we will create a
# PersistentVolumeClaim (PVC) and a Pod that uses this PVC to
# mount a volume. The PVC will request storage from the Local Path
# Provisioner, which will dynamically create a PersistentVolume (PV)
# using local storage on the node where the Pod is scheduled.
# The Pod will run an Nginx container and mount the volume at
# /data. This setup allows you to test the Local Path Provisioner
# by writing data to the mounted volume and verifying that it persists
# across Pod restarts.

resource "kubectl_manifest" "pvc" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "PersistentVolumeClaim"
    metadata = {
      name = "local-path-pvc"
    }
    spec = {
      accessModes = ["ReadWriteOnce"]
      resources = {
        requests = {
          storage = "10Gi"
        }
      }
      storageClassName = "local-path"
    }
  })
}

resource "kubectl_manifest" "pod" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Pod"
    metadata = {
      name = "volume-test"
    }
    spec = {
      containers = [
        {
          name            = "volume-test"
          image           = "nginx:stable-alpine"
          imagePullPolicy = "IfNotPresent"
          volumeMounts = [{
            name      = "vol"
            mountPath = "/data"
          }]
          ports = [{
            containerPort = 80
          }]
        }
      ]
      volumes = [
        {
          name = "vol"
          persistentVolumeClaim = {
            claimName = yamldecode(kubectl_manifest.pvc.yaml_body).metadata.name
          }
        }
      ]
    }
  })
}
