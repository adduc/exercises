##
# Exercise: creating a Github repository through Terraform
##

## Required Providers

terraform {
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
  description = <<-EOT
    The owner of the repository. This can be a user or organization.
  EOT
}

## Resources

resource "github_repository" "example" {
  name         = "example-terraform-managed-repo"
  description  = "An example repository managed by the Github Terraform provider"
  visibility   = "public"
  has_issues   = true
  has_projects = true
  has_wiki     = false
  auto_init    = true

  allow_squash_merge = true
  allow_merge_commit = false
  allow_rebase_merge = false
}

resource "github_repository_file" "example" {
  repository = github_repository.example.name
  file       = ".github/CODEOWNERS"
  content    = <<-EOT
    # This is a comment
    * @${var.owner}
  EOT
}
