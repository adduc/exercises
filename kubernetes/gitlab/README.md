# Provisioning GitLab using Helm

## Context

Years ago, I would routinely provision GitLab for local development and testing using their omnibus docker image. When I had a need to provision a GitLab instance for a project recently, I found that some application settings were not configurable via the omnibus image's environment variables. After some research, I found that GitLab's helm chart appeared to offer more flexibility and configurability, including the ability to specify custom application settings.
