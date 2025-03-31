# Running GitLab using Docker Compose (overriding gitlab.yml)

This exercise shows how GitLab can be provisioned and configured through
Docker Compose. It uses the omnibus image, which ships with all the
necessary components to run a GitLab instance, including the web server,
database, and other dependencies.

This specific exercise uses a custom gitlab.yml configuration file to
allow for greater customization of the GitLab instance vs. the settings
exposed through gitlab.rb.

## Context

One prospective company I'm interviewing with uses GitLab. While I have
experience provisioning and administering GitLab instances in the past,
it's been a few years and I wanted to understand how GitLab's
administration has evolved.

This particular iteration of the exercise came from frustration with
features that did not appear to be supported through the gitlab.rb
configuration file. While this approach works, I discovered GitLab has
has been discouraging the use of gitlab.yml for new settings. Instead,
they define application settings in their database and provide no way
to set these values through environment variables or the gitlab.rb
configuration file. It appears that the helm chart supports management of application settings directly through the chart values, and I intend to explore that in a future exercise.

## Usage

A Makefile is provided to simplify the process of starting and resetting
the GitLab instance. You can use the following commands:

- `make up`: Start the GitLab instance in detached mode and wait for it to be fully initialized. This may take a few minutes.
- `make reset`: Stop and remove the GitLab instance, including all associated data. This is useful for starting fresh.