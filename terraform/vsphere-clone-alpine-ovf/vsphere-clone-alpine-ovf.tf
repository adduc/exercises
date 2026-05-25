# @see https://registry.terraform.io/providers/vmware/vsphere/latest/docs

## Terraform Configuration

terraform {
  required_providers {
    vsphere = {
      source  = "vmware/vsphere"
      version = "2.15.2"
    }
    cloudinit = {
      source  = "marefr/cloudinit"
      version = "0.1.0"
    }
  }
}

## Provider Configuration

provider "vsphere" {
  user                 = var.vsphere.user
  password             = var.vsphere.password
  vsphere_server       = var.vsphere.vsphere_server
  allow_unverified_ssl = var.vsphere.allow_unverified_ssl
}


## Inputs

variable "vsphere" {
  description = "Configuration for the vSphere provider."
  type = object({
    user                 = string
    password             = string
    vsphere_server       = string
    allow_unverified_ssl = bool
  })
}

variable "cluster_name" {
  description = "The name of the compute cluster to use."
  type        = string
}

variable "datastore_name" {
  description = "The name of the datastore to use for the virtual machine."
  type        = string
}

variable "network_name" {
  description = "The name of the network to connect the virtual machine to."
  type        = string
}

variable "template_name" {
  description = "The name of the virtual machine template to clone from."
  type        = string
}

variable "folder_path" {
  description = "The path to the folder where the virtual machine will be created."
  type        = string
}

variable "vm_name" {
  description = "The name of the virtual machine to be created."
  type        = string
}

variable "user_data_username" {
  description = "The username for the user to be created in the virtual machine."
  type        = string
}


variable "user_data_ssh_public_key_path" {
  description = "The file path to the SSH public key to be added to the virtual machine."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

## Data Sources

data "vsphere_datacenter" "datacenter" {
  name = "Datacenter"
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
  name          = var.network_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.template_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_folder" "folder" {
  path = "${data.vsphere_datacenter.datacenter.name}/vm/${var.folder_path}"
}

## Resources


module "vsphere_virtual_machine" {
  source = "./modules/vsphere_alpine_vm_ovf"

  name             = var.vm_name
  folder           = replace(data.vsphere_folder.folder.path, "${data.vsphere_datacenter.datacenter.name}/vm/", "")
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datacenter_id    = data.vsphere_datacenter.datacenter.id
  datacenter_name  = data.vsphere_datacenter.datacenter.name
  datastore_id     = data.vsphere_datastore.datastore.id
  datastore_name   = var.datastore_name
  network_id       = data.vsphere_network.network.id
  num_cpus         = 1
  memory           = 1024
  disk             = 10

  template_info = {
    guest_id             = data.vsphere_virtual_machine.template.guest_id
    template_id          = data.vsphere_virtual_machine.template.id
    network_adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  user_data = {
    users = [{
      name                = var.user_data_username,
      shell               = "/bin/sh",
      lock_passwd         = false
      passwd              = ""
      doas                = ["permit nopass ${var.user_data_username} as root"]
      ssh_authorized_keys = [file(var.user_data_ssh_public_key_path)]
    }]
  }
}

## Outputs

output "default_ip_address" {
  value = module.vsphere_virtual_machine.default_ip_address
}
