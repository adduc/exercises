# Creating an Ubuntu 22.04 VM for VMware using Packer

This exercise demonstrates how Packer can be used to create a VMware
virtual machine (VM) with Ubuntu 22.04 as the operating system.

Influenced by <https://github.com/BytesGuy/arm-base-boxes>

## Lessons Learned

Ubuntu is very particular about its autoinstall configuration, and
there are multiple situations that can result in lengthy timeouts
without clear error messages.
