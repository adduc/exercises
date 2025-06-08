# Creating an Ubuntu 24.04 VM for VMware using Packer

This exercise demonstrates how Packer can be used to create an Ubuntu virtual machine (VM) in VMware ESXi. This is useful for creating templates and automating the provisioning of VMs in a VMware environment.

## Lessons Learned

I initially tried to use the `vsphere-iso` builder, but it turns out that it requires use of APIs that are not available in the free version of VMware ESXi. Instead, I used the `vmware-iso` builder, which uses SSH to connect to the VM during the build process. This approach works with the free version of VMware ESXi, but it requires the VM to be powered on and accessible via SSH.

I also found that the SSH communicator failed to get the IP of the VM during the build process when the VM contained spaces in its name. This was resolved by using a name without spaces.
