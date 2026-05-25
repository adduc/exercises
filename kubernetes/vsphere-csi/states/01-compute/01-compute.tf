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

variable "vm" {
  description = "Configuration for the virtual machine."
  type = object({
    name        = string
    folder_path = string

    cluster_name   = string
    datastore_name = string
    network_name   = string
    template_name  = string

    user_data_username            = string
    user_data_ssh_public_key_path = string
  })
}

## Data Sources

data "vsphere_datacenter" "datacenter" {
  name = "Datacenter"
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.vm.cluster_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_datastore" "datastore" {
  name          = var.vm.datastore_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
  name          = var.vm.network_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.vm.template_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_folder" "examples" {
  path = "${data.vsphere_datacenter.datacenter.name}/vm/${var.vm.folder_path}"
}

## Locals

locals {
  vm_static_ip     = "192.168.56.140"
  vm_ssh_identity  = trimsuffix(var.vm.user_data_ssh_public_key_path, ".pub")
}

## Resources

module "vm_k3s" {
  source = "../../modules/vsphere_alpine_vm"

  name             = var.vm.name
  folder           = replace(data.vsphere_folder.examples.path, "${data.vsphere_datacenter.datacenter.name}/vm/", "")
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datacenter_id    = data.vsphere_datacenter.datacenter.id
  datacenter_name  = data.vsphere_datacenter.datacenter.name
  datastore_id     = data.vsphere_datastore.datastore.id
  datastore_name   = var.vm.datastore_name
  network_id       = data.vsphere_network.network.id
  num_cpus         = 2
  memory           = 2048
  disk             = 10

  template_info = {
    guest_id             = data.vsphere_virtual_machine.template.guest_id
    template_id          = data.vsphere_virtual_machine.template.id
    network_adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  user_data = {
    write_files = [
      {
        path = "/etc/network/interfaces"
        content = <<-EOT
          auto lo
          iface lo inet loopback

          auto eth0
          iface eth0 inet static
              address 192.168.56.140
              netmask 255.255.255.0
              gateway 192.168.56.1
        EOT
      },
      {
        path    = "/etc/resolv.conf"
        content = "nameserver 8.8.8.8\nnameserver 8.8.4.4\n"
      },
      {
        # Longhorn requires bidirectional bind-mount propagation. Alpine's root
        # filesystem is not MS_SHARED by default, so containerd cannot start the
        # longhorn-manager container. This OpenRC service runs mount --make-rshared /
        # before k3s to satisfy that requirement.
        path = "/etc/init.d/shared-mounts"
        content = <<-EOT
          #!/sbin/openrc-run
          description="Make root mount shared for container runtimes"
          depend() {
              before k3s
          }
          start() {
              mount --make-rshared /
          }
        EOT
      }
    ]

    runcmd = [
      # k3s in 3.23.0 is missing required manifests; to mitigate for the time
      # being, we'll install k3s from edge-community
      # @see https://gitlab.alpinelinux.org/alpine/aports/-/issues/17772
      "echo \"@edge-community http://dl-cdn.alpinelinux.org/alpine/edge/community\" >> /etc/apk/repositories",
      "apk add --no-cache k3s@edge-community k3s-openrc@edge-community htop",
      "rc-update add k3s default",

      # set K3S_OPTS in /etc/conf.d/k3s to skip local path provisioner
      "sed -i 's/.*K3S_OPTS=.*/K3S_OPTS=\"--disable=local-storage --disable=metrics-server --disable=servicelb --disable=traefik\"/' /etc/conf.d/k3s",

      # Convert the raw DMI product_serial (e.g. "VMware-42 1e bb 74 2d a2 46 88-b9 5b...")
      # into a standard UUID (e.g. "421ebb74-2da2-4688-b95b-8b765bf29b10") and write it
      # into the K3s kubelet-arg so spec.providerID is set — required by vSphere CSI.
      "UUID=$(awk '{s=tolower($0); gsub(/[^0-9a-f]/,\"\",s); print substr(s,1,8)\"-\"substr(s,9,4)\"-\"substr(s,13,4)\"-\"substr(s,17,4)\"-\"substr(s,21,12)}' /sys/class/dmi/id/product_serial) && mkdir -p /etc/rancher/k3s && echo kubelet-arg: > /etc/rancher/k3s/config.yaml && echo \"  - provider-id=vsphere://$UUID\" >> /etc/rancher/k3s/config.yaml",

      # Longhorn prerequisites: iSCSI daemon, NFS client, bash, and block-device utilities.
      # iscsid and shared-mounts are registered here so they start after the cgroup reboot below.
      "apk add --no-cache open-iscsi nfs-utils bash util-linux curl",
      "chmod +x /etc/init.d/shared-mounts",
      "rc-update add shared-mounts default",
      "rc-update add iscsid default",
    ]

    # k3s requires cgroup, which requires a reboot to enable.
    power_state = {
      mode = "reboot"
    }

    users = [{
      name                = var.vm.user_data_username,
      shell               = "/bin/sh",
      lock_passwd         = false
      passwd              = ""
      doas                = ["permit nopass ${var.vm.user_data_username} as root"]
      ssh_authorized_keys = [file(var.vm.user_data_ssh_public_key_path)]
    }]
  }
}

# after module.vm_k3s, use local exec to ssh into the VM and dump the kubeconfig
# file locally to allow kubectl to access the k3s cluster running on the VM.

resource "null_resource" "k3s_kubeconfig" {
  depends_on = [module.vm_k3s]

  provisioner "local-exec" {
    command = <<EOT
      ssh -o "StrictHostKeyChecking=no" -i ${local.vm_ssh_identity} ${var.vm.user_data_username}@${local.vm_static_ip} "doas cat /etc/rancher/k3s/k3s.yaml" \
      | sed "s/127.0.0.1/${local.vm_static_ip}/g" \
      > ../../k3s_kubeconfig.yaml
    EOT
  }
}

## Outputs

output "vm_k3s_ip_address" {
  value = local.vm_static_ip
}
