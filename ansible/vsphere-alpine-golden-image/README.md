# Creating an Golden VM Image with Alpine Linux using Ansible

This exercise demonstrates how Ansible can be used to automate the creation of a
golden VM image with Alpine Linux on a vSphere environment. The process involves
downloading an Alpine Linux cloud image, customizing it with Ansible, and then
converting it into a format suitable for deployment on vSphere.

## Context

I have been working with vSphere environments a lot lately, and to make my life
easier, I wanted to investigate if I could automate the creation of a golden VM
image using Ansible. This would allow me to quickly deploy new VMs with a
pre-loaded set of tools and configurations, saving me time and effort in the
long run.

## Status

This exercise successfully downloads and imports an Alpine Linux cloud image,
creates a golden image by customizing it with Ansible, and clones the golden
image to showcase an example of how to use it for creating new VMs. The process
is fully automated and requires no human input once the playbook is executed.
