## Providers

provider "github" {
  owner = "adduc"
  token = var.github_token
}

## Required Providers

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

## Imports

import {
  to = github_repository.repo
  id = "exercises"
}

import {
  to = github_branch_default.default
  id = "exercises"
}

## Variables

variable "github_token" {
  type        = string
  description = "GitHub personal access token with repo scope."
}

## Resources

resource "github_repository" "repo" {
  name         = "exercises"
  description  = "proof of concept exercises for various technologies, functionality, design patterns, etc."
  has_projects = false

  # PRs
  allow_merge_commit     = false
  allow_rebase_merge     = false
  allow_squash_merge     = true
  delete_branch_on_merge = true
}

resource "github_branch_default" "default" {
  repository = github_repository.repo.name
  branch     = "main"
}

resource "github_branch_protection" "default" {
  repository_id = github_repository.repo.name
  pattern       = github_branch_default.default.branch

  required_status_checks {
    contexts = ["trufflehog"]
  }

  required_pull_request_reviews {
    required_approving_review_count = 0
  }
}
