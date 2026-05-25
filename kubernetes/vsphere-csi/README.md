# Installing the vSphere CSI Driver using Terraform

The vSphere CSI Driver is a Container Storage Interface (CSI) driver that allows
using disks in vSphere datastores as persistent volumes in Kubernetes. This
exercise demonstrates how the vSphere CSI Driver can be installed using
Terraform.

## Context

I have been working with vSphere a lot lately, and wanted to evaluate different
means of storage management in a local cluster.  When I learned about the
vSphere CSI Driver, I wanted to try it out.

## Status

I have successfully installed the vSphere CSI Driver using Terraform, and have
been able to create and use persistent volumes in Kubernetes using vSphere
datastores.
