# Notes: Github Actions

## Best Practices

- When using third-party actions, reference specific commit SHAs
  instead of tags or branches. This closes one method of attack when an
  action is compromised. It does not prevent all methods
  of attack when an action is compromised, but it mitigates some risks.
  For further information, look for the discourse around
  `tj-actions/changed-files/`'s compromise in 2025.

## Concerns

- Within branch protection rules, status checks require a static list of
  jobs. There is no support for wildcards, or for requiring all executed
  workflows to pass (independent of whether any workflows execute or
  not).
