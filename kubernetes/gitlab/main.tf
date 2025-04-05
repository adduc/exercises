##
# This example shows how to deploy GitLab into a
# Kubernetes cluster using Terraform.
#
# GitLab is a software forge akin to GitHub, with support for Git
# repositories, issue tracking, CI/CD, and more.
##

## Inputs

variable "initial_root_password" {
  type        = string
  description = <<-EOT
    Initial password to set for the root user in GitLab.

    Changing this value after the initial deployment will have no
    effect. You will need to manually change the root password in GitLab
    or reset it via the GitLab Rails console.

    @see https://gitlab.com/gitlab-org/charts/gitlab/-/tags
  EOT
}

variable "gitlab_chart_version" {
  type    = string
  default = "8.10.3"
}

variable "ssh_host_ecdsa_key" { type = string }
variable "ssh_host_ecdsa_key_pub" { type = string }
variable "ssh_host_ed25519_key" { type = string }
variable "ssh_host_ed25519_key_pub" { type = string }
variable "ssh_host_rsa_key" { type = string }
variable "ssh_host_rsa_key_pub" { type = string }

variable "root_personal_access_token" { type = string }

## Outputs

output "root_personal_access_token" {
  value       = var.root_personal_access_token
  sensitive   = true
  description = <<-EOT
    Token to use for the root user in GitLab after initial deployment.

    Terraform will not automatically configure this token for you. You
    will need to manually run `make gitlab/create-root-personal-access-token`
    to create the preseeded personal access token for the root user in
    GitLab.
  EOT
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

### GitLab

# Ensure the Kubernetes namespace for GitLab exists
resource "kubectl_manifest" "gitlab_namespace" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = "gitlab"
    }
  })
}

resource "kubectl_manifest" "initial_root_password" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "gitlab-initial-root-password"
      namespace = yamldecode(kubectl_manifest.gitlab_namespace.yaml_body)["metadata"]["name"]
    }
    type = "Opaque"
    data = {
      password = base64encode(var.initial_root_password)
    }
  })

  depends_on = [
    kubectl_manifest.gitlab_namespace
  ]
}

resource "kubectl_manifest" "gitlab_shell_host_keys" {
  # This is required for GitLab Shell to work properly
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "gitlab-shell-host-keys"
      namespace = yamldecode(kubectl_manifest.gitlab_namespace.yaml_body)["metadata"]["name"]
    }
    type = "Opaque"
    data = {
      "ssh_host_ecdsa_key"       = base64encode(var.ssh_host_ecdsa_key)
      "ssh_host_ecdsa_key.pub"   = base64encode(var.ssh_host_ecdsa_key_pub)
      "ssh_host_ed25519_key"     = base64encode(var.ssh_host_ed25519_key)
      "ssh_host_ed25519_key.pub" = base64encode(var.ssh_host_ed25519_key_pub)
      "ssh_host_rsa_key"         = base64encode(var.ssh_host_rsa_key)
      "ssh_host_rsa_key.pub"     = base64encode(var.ssh_host_rsa_key_pub)
    }
  })

  depends_on = [
    kubectl_manifest.gitlab_namespace
  ]
}

resource "helm_release" "gitlab" {
  name       = "gitlab"
  repository = "https://charts.gitlab.io"
  chart      = "gitlab"
  version    = var.gitlab_chart_version
  namespace  = yamldecode(kubectl_manifest.gitlab_namespace.yaml_body)["metadata"]["name"]

  values = [
    # @see https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/values.yaml
    # @see https://docs.gitlab.com/charts/charts/globals/#general-application-settings
    yamlencode({
      global = {
        edition = "ce"

        hosts = {
          domain = "172.17.0.1.nip.io"
          https  = false
        }

        ingress = {
          configureCertmanager = false
          tls = {
            enabled = false
          }
        }

        initialRootPassword = {
          secret = yamldecode(kubectl_manifest.initial_root_password.yaml_body)["metadata"]["name"]
          key    = "password"
        }

        appConfig = {
          defaultTheme                   = 11
          defaultColorMode               = 2 # Dark
          defaultSyntaxHighlightingTheme = 2 # Dark

          enableUsagePing = false
          enableSeatLink  = false

          initialDefaults = {
            signupEnabled = false
          }
        }

        shell = {
          hostKeys = {
            secret = yamldecode(kubectl_manifest.gitlab_shell_host_keys.yaml_body)["metadata"]["name"]
          }
          port = 2222
        }
      }

      certmanager = {
        install = false
      }

      nginx-ingress = {
        controller = {
          service = {
            type = "NodePort"
            nodePorts = {
              http         = 30080
              gitlab-shell = 30022
            }
            enableHttps = false
          }
        }
      }
    })
  ]
}
