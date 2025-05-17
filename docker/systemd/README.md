# Running Systemd in a Docker Container

Because Systemd uses cgroups and other features that are typically managed by the host system, running it inside a Docker container requires some specific configurations. This exercise demonstrates a configuration that allows Systemd to run inside a Docker container.

## Host Environment

This was tested on a Fedora 41 host with no adjustments made to either the linux kernel parameters or the docker daemon configuration.
