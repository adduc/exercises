##
# This example shows how ddns-updater can be used to manage
# a dynamic DNS domain using Porkbun as the DNS provider.
##

## Inputs

variable "ddns_domain" {
  description = "The DDNS domain to be managed"
  type        = string
}

variable "porkbun_api_key" {
  description = "Porkbun API Key"
  type        = string
  sensitive   = true
}

variable "porkbun_api_secret" {
  description = "Porkbun API Secret"
  type        = string
  sensitive   = true
}

variable "resolver_address" {
  description = "The DNS resolver address to use"
  type        = string
  default     = "1.1.1.1:53"
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

module "ddns_updater" {
  source           = "./modules/ddns-updater"
  resolver_address = var.resolver_address
  service_type     = "NodePort"
  node_port        = 30080

  settings = [
    {
      provider       = "porkbun"
      domain         = var.ddns_domain
      api_key        = var.porkbun_api_key
      secret_api_key = var.porkbun_api_secret
      ip_version     = "ipv4"
    }
  ]
}
