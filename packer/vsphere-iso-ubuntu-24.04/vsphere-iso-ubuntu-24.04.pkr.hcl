## Packer Configuration

packer {
  required_plugins {
    vsphere = {
      version = "~> 1"
      source  = "github.com/hashicorp/vsphere"
    }
  }
}

## Input Variables

variable "vm_password" {
  type        = string
  description = "The password for the default user."
}

variable "vm_password_hash" {
  type        = string
  description = <<-EOT
    The password hash for the default user.

    This can be generated with the command `mkpasswd`
  EOT
}

variable "vcenter_server" {
  type        = string
  description = "The vCenter server address."
}
variable "vcenter_username" {
  type        = string
  description = "The vCenter username."
}
variable "vcenter_password" {
  type        = string
  description = "The vCenter password."
}
variable "vcenter_cluster" {
  type        = string
  description = "The vCenter cluster."
}
variable "vcenter_datastore" {
  type        = string
  description = "The vCenter datastore."
}
variable "vcenter_network" {
  type        = string
  description = "The vCenter network."
}
variable "insecure_connection" {
  type        = bool
  description = "Whether to allow insecure connections to vCenter."
}

## Build Configuration

# @see https://developer.hashicorp.com/packer/integrations/hashicorp/vsphere/latest/components/builder/vsphere-iso
source "vsphere-iso" "ubuntu-noble" {

  # vCenter Server details
  vcenter_server      = var.vcenter_server
  username            = var.vcenter_username
  password            = var.vcenter_password
  cluster             = var.vcenter_cluster
  datastore           = var.vcenter_datastore
  insecure_connection = var.insecure_connection

  vm_name      = "Ubuntu Server 24.04.2"
  RAM          = 4096
  RAM_hot_plug = true
  CPUs         = 4
  CPU_hot_plug = true

  storage {
    disk_size             = 15000
    disk_thin_provisioned = true
  }

  network_adapters {
    network      = var.vcenter_network
    network_card = "vmxnet3"
  }

  iso_url      = "https://releases.ubuntu.com/24.04.2/ubuntu-24.04.2-live-server-amd64.iso"
  iso_checksum = "sha256:d6dab0c3a657988501b4bd76f1297c053df710e06e0c3aece60dead24f270b4d"

  ssh_username = "ubuntu"
  ssh_password = var.vm_password
  ssh_timeout  = "15m"

  snapshot_name = "Installed"

  boot_wait = "10s"
  boot_command = [
    "e<wait><down><down><down><end>",
    " autoinstall ds=\"nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/\"",
    "<F10>",
  ]

  http_content = {
    "/meta-data" = ""
    "/user-data" = <<-EOT
      #cloud-config
      autoinstall:
        version: 1
        locale: en_US
        keyboard:
          layout: us
        timezone: America/Chicago
        source:
          id: ubuntu-server-minimal
        kernel:
          package: linux-image-kvm
        identity:
          hostname: ubuntu
          username: ubuntu
          password: ${var.vm_password_hash}
        ssh:
          install-server: true
          allow-pw: true
        package_update: false
        package_upgrade: false
        packages:
          - open-vm-tools
        late-commands:
          - echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/ubuntu
          - chmod 440 /target/etc/sudoers.d/ubuntu
    EOT
  }

  # It can take some time for vCenter to recognize VMWare Tools are
  # installed, which the builder relies on to shutdown the VM after
  # installation. To prevent this type of error, we can use a shutdown
  # command over SSH to ensure the VM gracefully shuts down after SSH
  # is available.
  shutdown_command = "echo '${var.vm_password}' | sudo -S shutdown -P now"
}

build {
  sources = ["sources.vsphere-iso.ubuntu-noble"]
}
