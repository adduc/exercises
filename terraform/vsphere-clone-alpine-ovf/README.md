# Cloning an Alpine Linux Template on vSphere with Terraform (OVF Cloud-Init)

This exercise shows how Terraform can be used to clone an Alpine Linux
Template VM on vSphere, and use Cloud-Init with the OVF datasource to
configure the VM on first boot.

## Context

I have been working with vSphere a lot recently, and wanted to explore how ways
to automate VM provisioning on vSphere. After successfully creating a golden
image of Alpine Linux and cloning it with Ansible, I wanted to replicate the
cloning process with Terraform with the idea that Terraform could be used to
manage the lifecycle of the VM after it is provisioned.

## Prerequisites

This exercise assumes the golden image from
<../ansible/vsphere-alpine-golden-image-cloud-init-ovf> has been created
and is available as a template on vSphere.
