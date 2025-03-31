# Running GitLab using Docker Compose

This exercise shows how GitLab can be provisioned and configured through
Docker Compose. It uses the omnibus image, which ships with all the
necessary components to run a GitLab instance, including the web server,
database, and other dependencies.

## Context

One prospective company I'm interviewing with uses GitLab. While I have
experience provisioning and administering GitLab instances in the past,
it's been a few years and I wanted to understand how GitLab's
administration has evolved.

## Usage

A Makefile is provided to simplify the process of starting and resetting
the GitLab instance. You can use the following commands:

- `make up`: Start the GitLab instance in detached mode and wait for it to be fully initialized. This may take a few minutes.
- `make reset`: Stop and remove the GitLab instance, including all associated data. This is useful for starting fresh.