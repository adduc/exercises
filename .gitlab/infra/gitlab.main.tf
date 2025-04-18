##
# GitLab Project Configuration
##

## Inputs

variable "base_url" {
  type        = string
  description = "The base URL for the GitLab instance."
}

variable "token" {
  type        = string
  sensitive   = true
  description = <<-EOT
    The OAuth2 Token, Project, Group, Personal Access Token or CI Job
    Token used to connect to GitLab
  EOT
}

## Providers

provider "gitlab" {
  base_url = var.base_url
  token    = var.token
}

## Required Providers

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "17.10.0"
    }
  }
}

## Resources

resource "gitlab_project" "project" {
  name             = "exercises"
  visibility_level = "public"
  default_branch   = "main"
  squash_option    = "always"
}

resource "gitlab_branch_protection" "main" {
  project = gitlab_project.project.id
  branch  = gitlab_project.project.default_branch

  push_access_level      = "maintainer"
  merge_access_level     = "developer"
  unprotect_access_level = "maintainer"
  allow_force_push       = false
}
