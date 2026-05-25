## Terraform Configuration

terraform {
  required_providers {
    vsphere = {
      source = "vmware/vsphere"
    }
    cloudinit = {
      source = "marefr/cloudinit"
    }
  }
}

## Inputs

variable "name" {
  description = "The name of the virtual machine."
  type        = string
}

variable "folder" {
  description = "The folder path for the virtual machine."
  type        = string
}

variable "resource_pool_id" {
  description = "The ID of the resource pool for the virtual machine."
  type        = string
}

variable "template_info" {
  description = "A map of required template_info for the virtual machine."
  type = object({
    guest_id             = string
    template_id          = string
    network_adapter_type = string
  })
}

variable "datacenter_id" {
  description = "The ID of the datacenter for the virtual machine."
  type        = string
}

variable "datacenter_name" {
  description = "The name of the datacenter (required for cloud-init ISO upload)."
  type        = string
}

variable "datastore_id" {
  description = "The ID of the datastore for the virtual machine."
  type        = string
}

variable "datastore_name" {
  description = "The name of the datastore (required for cloud-init ISO upload)."
  type        = string
}

variable "network_id" {
  description = "The ID of the network for the virtual machine."
  type        = string
}

variable "num_cpus" {
  description = "The number of CPUs for the virtual machine."
  type        = number
  default     = 1
}

variable "memory" {
  description = "The amount of memory (in MB) for the virtual machine."
  type        = number
  default     = 1024
}

variable "disk" {
  description = "The size of the disk (in GB) for the virtual machine."
  type        = number
  default     = 10
}

variable "user_data" {
  description = <<-EOT
    A map of user data for cloud-init configuration.

    Along with any additional user data provided, the module will automatically
    include a "hostname" key with the value set to the name of the virtual
    machine. This ensures that the cloned VM is properly identified in the
    network and can be easily managed.
  EOT
  type        = map(any)
  default     = {}
}

## Locals

locals {
  cloud_config = join("\n", [
    "#cloud-config",
    yamlencode(merge(var.user_data, { hostname = var.name }))
  ])
  meta_data = yamlencode({
    "instance-id"    = "iid-${var.name}"
    "local-hostname" = var.name
  })
  iso_datastore_path = "cloud-init/${var.name}-cidata.iso"
}

# Resources

resource "cloudinit_iso" "cloud_init" {
  name      = "${var.name}-cidata.iso"
  user_data = local.cloud_config
  meta_data = local.meta_data

  lifecycle {
    ignore_changes = [
      user_data,
      meta_data
    ]
  }
}

resource "vsphere_file" "cloud_init_iso" {
  datacenter         = var.datacenter_id
  datastore          = var.datastore_name
  source_file        = cloudinit_iso.cloud_init.path
  destination_file   = local.iso_datastore_path
  create_directories = true

  lifecycle {
    ignore_changes = [
      source_file
    ]
  }
}

resource "vsphere_virtual_machine" "vm" {
  name             = var.name
  resource_pool_id = var.resource_pool_id
  datastore_id     = var.datastore_id
  guest_id         = var.template_info.guest_id

  folder   = var.folder
  firmware = "efi"
  num_cpus = var.num_cpus
  memory   = var.memory

  network_interface {
    network_id   = var.network_id
    adapter_type = var.template_info.network_adapter_type
  }

  disk {
    label = "disk0"
    size  = var.disk
  }

  clone {
    template_uuid = var.template_info.template_id
  }

  vapp {
    properties = {
      "instance-id" = "iid-${var.name}"
      "user-data" = base64encode(join("\n", [
        "#cloud-config",
        yamlencode(merge(var.user_data, { hostname = var.name }))
      ]))
    }
  }

  lifecycle {
    ignore_changes = [
      vapp[0].properties["instance-id"],
      vapp[0].properties["user-data"],
    ]
  }
}

## Outputs

output "default_ip_address" {
  value = vsphere_virtual_machine.vm.default_ip_address
}
