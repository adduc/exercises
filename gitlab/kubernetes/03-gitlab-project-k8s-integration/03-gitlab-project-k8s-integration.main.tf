##
# This example shows how to deploy GitLab into a
# Kubernetes cluster using Terraform.
#
# GitLab is a software forge akin to GitHub, with support for Git
# repositories, issue tracking, CI/CD, and more.
##

## Inputs

variable "root_personal_access_token" { type = string }

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
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 18.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

## Provider Configuration

provider "helm" {
  kubernetes {
    config_path = "${path.module}/../kubeconfig.yaml"
  }
}

provider "kubectl" {
  config_path = "${path.module}/../kubeconfig.yaml"
}

provider "gitlab" {
  token    = var.root_personal_access_token
  base_url = "https://gitlab.172.17.0.1.nip.io/api/v4/"
  insecure = true
}

provider "kubernetes" {
  config_path = "${path.module}/../kubeconfig.yaml"
}

## Resources

resource "gitlab_group" "example" {
  name = "example-group"
  path = "example-group"
}

resource "gitlab_project" "example" {
  name             = "cluster-example"
  visibility_level = "private"
  namespace_id     = gitlab_group.example.id
}

resource "gitlab_cluster_agent" "example" {
  name    = "example-agent"
  project = gitlab_project.example.id
}

resource "gitlab_cluster_agent_token" "example" {
  project  = gitlab_project.example.id
  agent_id = gitlab_cluster_agent.example.agent_id
  name     = "example-token"
}

resource "gitlab_repository_file" "example" {
  project        = gitlab_cluster_agent.example.project
  branch         = gitlab_project.example.default_branch
  file_path      = ".gitlab/agents/${gitlab_cluster_agent.example.name}/config.yaml"
  encoding       = "text"
  content        = <<-EOT
    observability:
      logging:
        level: debug
        grpc_level: warn
    user_access:
      access_as:
        agent: {} # for free
      projects:
        - id: ${gitlab_group.example.name}/${gitlab_project.example.name}
      groups:
        - id: ${gitlab_group.example.name}

    ci_access:
      projects:
        - id: ${gitlab_group.example.name}/${gitlab_project.example.name}
  EOT
  author_email   = "root@gitlab.172.17.0.1.nip.io"
  author_name    = "GitLab Agent"
  commit_message = "Add GitLab Agent config"
}

resource "gitlab_repository_file" "ci" {
  project        = gitlab_cluster_agent.example.project
  branch         = gitlab_project.example.default_branch
  file_path      = ".gitlab-ci.yml"
  encoding       = "text"
  content        = <<-EOT
    deploy:
      image:
        name: bitnami/kubectl:latest
        entrypoint: ['']
      script:
        - kubectl --insecure-skip-tls-verify=true config get-contexts
        - kubectl --insecure-skip-tls-verify=true config use-context ${gitlab_group.example.name}/cluster-example:example-agent
        - kubectl --insecure-skip-tls-verify=true get pods
  EOT
  author_email   = "root@gitlab.172.17.0.1.nip.io"
  author_name    = "GitLab Agent"
  commit_message = "Add GitLab Agent config"
}

resource "gitlab_project_environment" "example" {
  project          = gitlab_project.example.id
  name             = "test"
  cluster_agent_id = gitlab_cluster_agent.example.agent_id
}

data "kubernetes_secret_v1" "example" {
  metadata {
    name      = "gitlab-wildcard-tls-chain"
    namespace = "gitlab"
  }
}

resource "helm_release" "gitlab_agent" {
  name             = "gitlab-agent"
  namespace        = "gitlab-agent"
  create_namespace = true
  repository       = "https://charts.gitlab.io"
  chart            = "gitlab-agent"
  version          = "v2.15.0"

  values = [
    # @see https://gitlab.com/gitlab-org/charts/gitlab-agent
    yamlencode({
      image = {
        tag = "v18.0.1"
      }

      config = {
        token      = gitlab_cluster_agent_token.example.token
        kasAddress = "wss://gitlab.172.17.0.1.nip.io/-/kubernetes-agent/"
        kasCaCert  = data.kubernetes_secret_v1.example.data["gitlab.172.17.0.1.nip.io.crt"]
      }
    })
  ]
}
