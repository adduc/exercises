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