## Packer Configuration

packer {
  required_plugins {
    vmware = {
      version = "~> 1"
      source  = "github.com/hashicorp/vmware"
    }
  }
}

## Input Variables

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

source "vmware-iso" "ubuntu-2204" {

  # @see https://www.releases.ubuntu.com/22.04/
  iso_url = "https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso"

  # @see https://www.releases.ubuntu.com/22.04/SHA256SUMS
  iso_checksum = "sha256:9bc6028870aef3f74f4e16b900008179e78b130e6b0b9a140635434a46aa98b0"

  vm_name      = "Ubuntu Server 22.04.5"
  ssh_username = "ubuntu"
  ssh_password = var.password
  memory       = 4096
  cpus         = 4
  disk_size    = 40000

  vhv_enabled          = true
  network_adapter_type = "vmxnet3"
  ssh_timeout          = "30m"
  shutdown_command     = "sudo shutdown -h now"
  guest_os_type        = "ubuntu-64"

  # Use of snapshot requires workstation (not player) to work. Newer versions of
  # the vmware plugin should handle starting workstation automatically, but I
  # needed to run `sudo touch /etc/vmware/license-ws-foo` as described in
  # https://github.com/hashicorp/packer-plugin-vmware/issues/242 for workstation
  # to start for me.
  snapshot_name    = "Installed"
  output_directory = "output"

  headless = true

  boot_wait         = "5s"
  boot_key_interval = "5ms"
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
          swap:
            size: 0
          layout:
            name: direct

        ssh:
          install-server: true
          allow-pw: true

        package_update: false
        package_upgrade: false
        packages:
          - open-vm-tools

        early-commands:
          # Disable unattended-upgrades
          - ( FILE="/target/usr/bin/unattended-upgrade" ; until [ -e "$FILE" ] ; do sleep 1 ; done ; sed -i '1i#!/bin/true' "$FILE" ) &
        late-commands:
          # Re-enable unattended-upgrades
          - sed -i '\,^#!/bin/true$,d' "/target/usr/bin/unattended-upgrade"

        user-data:
          hostname: ubuntu
          users:
            - name: ubuntu
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
  sources = ["sources.vmware-iso.ubuntu-2204"]
}
