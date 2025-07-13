# Creating an Ubuntu 24.04 VM for VMware using Packer

This exercise demonstrates how Packer can be used to create a virtual
machine on vCenter with Ubuntu 24.04 as the operating system.

Influenced by <https://github.com/BytesGuy/arm-base-boxes>

## Context

A client I am working with has a vSphere environment, and I wanted to
automate creation of a few new VMs. I have used Packer in the past
primarily for AWS EC2 images, but did not have any experience with
VMware.

## Lessons Learned

The vmware-iso and vsphere-iso builders differ a bit in configuration
options, which prevents copy-pasting between them.

## Prerequisites

- Hashicorp Packer
- A vSphere environment with a vCenter server
- A vSphere user with permissions to create VMs

## Configuration

Packer supports automatically loading variables from any file with the
suffix `.auto.pkrvars.hcl`. An example file is available as
`vsphere-iso-ubuntu-24.04.auto.pkrvars.dist.hcl` and can be copied to
`vsphere-iso-ubuntu-24.04.auto.pkrvars.hcl` and edited with your
vSphere configuration.

## Usage

A makefile is provided to simplify the build process. The default
target is `help`, which will display the available commands and a brief
description of each.

To build the VM image, run:

```bash
# Install dependencies
make init
# Build the VM image
make build
```

## Notes

Builds appear to randomly fail during shutdown with the following error:

```plaintext
error shutting down virtual machine: ServerFaultCode: Cannot complete
operation because VMware Tools is not running in this virtual machine.
```
