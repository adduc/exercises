# Running Ansible against an Alpine Docker container

This exercise demonstrates how Ansible can be run against a Docker
container over SSH when executing playbooks. This can be useful for to
mock what would happen in a production environment, or to test Ansible
playbooks without needing to deploy them to a real server.

## Context

I have worked at multiple companies where Ansible was used to manage
infrastructure. To increase confidence during development, I typically
used Docker to run Ansible playbooks against a container that tried to
mimic the production environment as closely as possible.

## Usage

Both a docker-compose file and a Makefile are provided to simplify the
process of running Ansible within Docker.

Running `make` will list available recipes and their descriptions.
