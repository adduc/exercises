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

  delete_branch_on_merge = true
}