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

source "virtualbox-iso" "ubuntu-noble" {
  iso_url      = "https://releases.ubuntu.com/24.04.2/ubuntu-24.04.2-live-server-amd64.iso"
  iso_checksum = "sha256:d6dab0c3a657988501b4bd76f1297c053df710e06e0c3aece60dead24f270b4d"
  vm_name      = "Ubuntu Server 24.04.2"

  ssh_username     = "ubuntu"
  ssh_password     = var.password
  ssh_timeout      = "30m"
  shutdown_command = "sudo shutdown -h now"
  guest_os_type    = "Ubuntu24_LTS_64"
  memory           = 4096
  cpus             = 4
  disk_size        = 40000

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
  sources = ["sources.virtualbox-iso.ubuntu-noble"]
}
