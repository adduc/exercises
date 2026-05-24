# Creating an Golden VM Image with Alpine Linux using Ansible

This exercise demonstrates how Ansible can be used to automate the creation of a
golden VM image with Alpine Linux on a vSphere environment. The process involves
downloading an Alpine Linux cloud image, customizing it with Ansible, and then
converting it into a format suitable for deployment on vSphere.

This specific exercise builds on `../vsphere-alpine-golden-image-cloud-init-nocloud`
by implementing the use of cloud-init's OVF datasource instead of NoCloud. This
allows for the use of vApp properties to pass cloud-init configuration to the
VM, which can be more flexible and easier to manage in a vSphere environment.

## Context

After creating an initial golden image for Alpine Linux using Ansible and the
NoCloud datasource, I wanted to investigate if it was possible to emulate how
Ubuntu's cloud images supported vApp properties to pass cloud-init configuration
to the VM.

## Status

This exercise successfully downloads and imports an Alpine Linux cloud image,
creates a golden image by customizing it with Ansible, and clones the golden
image to showcase an example of how to use it for creating new VMs. The process
is fully automated and requires no human input once the playbook is executed.

Once the golden image is created, the process of creating a new VM from the
golden image and passing cloud-init configuration through vApp properties
is also automated (and takes fewer steps than the NoCloud approach). The new VM
is successfully created and configured with the provided cloud-init
configuration, demonstrating the use of the OVF datasource with vApp properties
in a vSphere environment.
