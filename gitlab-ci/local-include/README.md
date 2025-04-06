# Locally included GitLab CI pipelines

This exercise demonstrates how to use local includes in GitLab CI/CD to
modularize your `.gitlab-ci.yml` configuration. By breaking down the
pipeline into smaller, reusable components, you can improve readability
and maintainability.

## Context

It has been a few years since I last used GitLab, and I want to
re-familiarize myself with its features, especially GitLab CI. To keep
my GitLab CI configuration organized and maintainable, I have opted to
use local includes. This allows me to break down the `.gitlab-ci.yml`
file into smaller, more manageable pieces.

## Usage

To use the locally included GitLab CI pipeline, you can create a
`.gitlab-ci.yml` file in your repository's root directory and include
the local file as shown below:

```yml
include:
  - local: 'gitlab-ci/local-include/local-include.gitlab-ci.yml'
```

This will include the pipeline defined in
`gitlab-ci/local-include/local-include.gitlab-ci.yml` into your main
`.gitlab-ci.yml`. You can then add additional local includes or jobs as
needed.
