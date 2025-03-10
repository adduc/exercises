## Providers

provider "github" {
  owner = "adduc"
}

## Imports

import {
  to = github_repository.repo
  id = "exercises"
}

## Resources

resource "github_repository" "repo" {
  name = "exercises"

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
  repository_id = github_repository.repo.id
  pattern       = github_branch_default.default.branch

  required_pull_request_reviews {
    required_approving_review_count = 0
  }
}