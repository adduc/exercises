## Providers

provider "github" {
  owner = "adduc"
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

