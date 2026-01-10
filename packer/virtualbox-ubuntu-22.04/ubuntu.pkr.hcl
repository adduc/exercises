## Packer Configuration

packer {
  required_plugins {
    virtualbox = {
      version = "~> 1"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}


## Input Variables

variable "hostname" {
  type        = string
  description = "The hostname for the VM."
}

variable "username" {
  type        = string
  description = "The username for the default user."
}

variable "password" {
  type        = string
  description = "The password for the default user."
}

variable "password_hash" {
  type        = string
  description = <<-EOT
    The password hash for the default user.

    This can be generated with the command `mkpasswd`
  EOT
}

## Build Configuration

source "virtualbox-iso" "ubuntu-2204" {
  # @see https://releases.ubuntu.com/22.04/
  iso_url = "https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso"
  # @see https://releases.ubuntu.com/22.04/SHA256SUMS
  iso_checksum = "sha256:9bc6028870aef3f74f4e16b900008179e78b130e6b0b9a140635434a46aa98b0"

  vm_name              = "Ubuntu Server 22.04.5"
  ssh_username         = var.username
  ssh_password         = var.password
  ssh_timeout          = "30m"
  shutdown_command     = "sudo shutdown -h now"
  guest_os_type        = "Ubuntu22_LTS_64"
  memory               = 4096
  cpus                 = 4
  disk_size            = 40000
  guest_additions_mode = "disable"

  output_directory = "output"

  boot_wait = "4s"
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

        storage:
          layout:
            name: direct
          swap:
            size: 0

        ssh:
          install-server: true
          allow-pw: true

        package_update: true
        package_upgrade: true
        packages:
          - open-vm-tools

        early-commands:
          # Disable unattended-upgrades
          - ( FILE="/target/usr/bin/unattended-upgrade" ; until [ -e "$FILE" ] ; do sleep 1 ; done ; sed -i '1i#!/bin/true' "$FILE" ) &
        late-commands:
          # Re-enable unattended-upgrades
          - sed -i '\,^#!/bin/true$,d' "/target/usr/bin/unattended-upgrade"

        user-data:
          hostname: ${var.hostname}
          users:
            - name: ${var.username}
              shell: /bin/bash
              lock_passwd: false
              passwd: ${var.password_hash}
              sudo: ALL=(ALL) NOPASSWD:ALL
              ssh_authorized_keys:
                - ${file("~/.ssh/id_ed25519.pub")}
    EOT
  }
}

build {
  sources = ["sources.virtualbox-iso.ubuntu-2204"]
}
