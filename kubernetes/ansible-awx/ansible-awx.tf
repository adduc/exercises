##
# This example shows how AWX (Ansible AWX and its operator) can be deployed in a Kubernetes
# cluster using Terraform, Helm, and Kubectl providers.
##

## Inputs

variable "admin_user" {
  type        = string
  description = "Admin user for AWX"
}

variable "admin_email" {
  type        = string
  description = "Admin email for AWX"
}

variable "admin_password" {
  type        = string
  description = "Admin password for AWX"
  sensitive   = true
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
# AWX Operator: an operator for running AWX on Kubernetes
#
# @see https://github.com/ansible/awx-operator
# @see https://github.com/ansible-community/awx-operator-helm
##
resource "helm_release" "awx-operator" {
  name       = "my-awx-operator"
  repository = "https://ansible-community.github.io/awx-operator-helm/"
  chart      = "awx-operator"
  version    = "3.2.0"

  # @see https://github.com/ansible-community/awx-operator-helm/blob/main/charts/awx-operator/values.yaml
  values = [

  ]
}

resource "kubectl_manifest" "awx-admin-password-secret" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name = "awx-admin-password"
    }
    stringData = {
      password = var.admin_password
    }
  })
}

##
# AWX: web UI for Ansible
#
# @see https://github.com/ansible/awx
# @see https://ansible.readthedocs.io/projects/awx-operator/en/latest/
##
resource "kubectl_manifest" "awx-instance" {
  depends_on = [helm_release.awx-operator, kubectl_manifest.awx-admin-password-secret]

  yaml_body = yamlencode({
    apiVersion = "awx.ansible.com/v1beta1"
    kind       = "AWX"
    metadata = {
      name = "awx-demo"
    }
    spec = {
      service_type  = "nodeport"
      nodeport_port = 30080


      admin_user            = var.admin_user
      admin_email           = var.admin_email
      admin_password_secret = "awx-admin-password"
    }
  })
}
