##
# Exercise: creating a Github repository through Terraform
##

## Required Providers

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.5.0"
    }
  }
}

## Providers

# @see https://registry.terraform.io/providers/integrations/github/latest
provider "github" {
  owner = var.owner
}

## Inputs

variable "owner" {
  type        = string
  description = <<-EOT
    The owner of the repository. This can be a user or organization.
  EOT
}

## Resources

resource "github_repository" "example" {
  name        = "example-terraform-managed-repo"
  description = "An example repository managed by the Github Terraform provider"
  visibility  = "public"

  allow_squash_merge = true
  allow_merge_commit = false
  allow_rebase_merge = false
}

resource "github_branch_default" "example" {
  repository = github_repository.example.name
  branch     = "main"
}

resource "github_repository_file" "example" {
  repository = github_repository.example.name
  file       = ".github/CODEOWNERS"
  content    = <<-EOT
    # This is a comment
    * @${var.owner}
  EOT
}
