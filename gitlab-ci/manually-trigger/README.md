# Manually triggered pipelines in GitLab CI

This exercise demonstrates how pipelines can be defined in GitLab CI to be manually triggered with variables set through a form.

## Context

It has been a few years since I last used GitLab, and I want to
re-familiarize myself with its features, especially GitLab CI.

## Lessons Learned

GitLab supports manual variables when creating pipelines for branches/tags, but it [does not support manual variables for merge request pipelines][1].

<!-- Links -->

[1]: https://gitlab.com/gitlab-org/gitlab/-/issues/118798
