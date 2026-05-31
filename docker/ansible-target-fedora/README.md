# Running Ansible against a Fedora Docker container

This exercise demonstrates how Ansible can be run against a Docker
container over SSH when executing playbooks. This can be useful for to
mock what would happen in a production environment, or to test Ansible
playbooks without needing to deploy them to a real server.

## Context

I have some Ansible playbooks that were written against Fedora systems.
To allow for isolated development and testing of these playbooks, I was
interested in running Ansible against a Fedora container where I could
easily reset the state of the container if needed.

## Usage

Both a docker-compose file and a Makefile are provided to simplify the
process of running Ansible within Docker.

Running `make` will list available recipes and their descriptions.
