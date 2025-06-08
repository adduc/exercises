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

# @see https://developer.hashicorp.com/packer/integrations/hashicorp/vmware/latest/components/builder/iso
source "vmware-iso" "ubuntu-noble" {
  iso_url      = "https://releases.ubuntu.com/24.04.2/ubuntu-24.04.2-live-server-amd64.iso"
  iso_checksum = "sha256:d6dab0c3a657988501b4bd76f1297c053df710e06e0c3aece60dead24f270b4d"
  vm_name      = "ubuntu_server_24.04.2"


  remote_type         = "esx5"
  remote_host         = var.remote_host
  remote_username     = var.remote_username
  remote_password     = var.remote_password
  vnc_over_websocket  = true
  insecure_connection = true

  ssh_username         = "ubuntu"
  ssh_password         = var.password
  ssh_timeout          = "30m"
  shutdown_command     = "sudo shutdown -h now"
  guest_os_type        = "ubuntu-64"
  memory               = 4096
  cpus                 = 4
  disk_size            = 40000
  vhv_enabled          = true
  network_adapter_type = "vmxnet3"
  network_name         = "VM Network"
  disk_type_id         = "thin"
  skip_export          = true
  keep_registered      = true
  skip_compaction      = true


  # Use of snapshot requires workstation (not player) to work. Newer versions of
  # the vmware plugin should handle starting workstation automatically, but I
  # needed to run `sudo touch /etc/vmware/license-ws-foo` as described in
  # https://github.com/hashicorp/packer-plugin-vmware/issues/242 for workstation
  # to start for me.
  snapshot_name = "Installed"
  # output_directory = "output"

  boot_wait         = "10s"
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
        kernel:
          package: linux-image-kvm
        identity:
          hostname: ubuntu
          username: ubuntu
          password: ${var.password_hash}
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
}

build {
  sources = ["sources.vmware-iso.ubuntu-noble"]
}
