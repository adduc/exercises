##
# Creating a Free-Tier-eligible Instance on Oracle Cloud Infrastructure
# (OCI) using Terraform
##

## Input Variables

variable "parent_compartment_id" {
  description = <<-EOT
    The OCID of the compartment where the resources will be created.

    This is typically the root compartment or a specific compartment
    where you have permissions to create resources.
  EOT
  type        = string
}

variable "image_operating_system" {
  type        = string
  description = <<-EOT
    The operating system to use for the instance image.

    This should match the operating system of the image you want to
    use, such as "Canonical Ubuntu", "Oracle Linux", etc.
  EOT
}

variable "image_operating_system_version" {
  type        = string
  description = <<-EOT
    The version of the operating system to use for the instance image.

    This should match the version of the image you want to use, such
    as "22.04 Minimal", "8.6", etc.
  EOT
}

variable "instance_shape" {
  type        = string
  description = <<-EOT
    The shape of the instance to create.

    This defines the hardware configuration of the instance, such as
    "VM.Standard.E2.1.Micro" for AMD or "VM.Standard.A1.Flex" for ARM.
    The shape determines the number of OCPUs, memory, and other
    resources available to the instance.
  EOT
}

variable "instance_memory_in_gbs" {
  type        = number
  description = <<-EOT
    The amount of memory (in GB) to allocate for the instance.

    Some shapes allow a range of memory configurations, so this value
    should be within the limits of the selected instance shape.
  EOT
}

variable "instance_ocpus" {
  type        = number
  description = <<-EOT
    The number of physical CPU cores (OCPUs) to allocate for the
    instance.

    Some shapes allow a range of OCPU configurations, so this value
    should be within the limits of the selected instance shape.
  EOT
}

variable "ssh_authorized_key_path" {
  type        = string
  description = <<-EOT
    The path to the SSH public key file used for instance access.

    This key will be used when the instance initially boots to
    allow SSH access. CHANGING THIS KEY AFTER THE INSTANCE IS
    CREATED WILL NOT WORK. You'll need to update the authorized keys
    file on the instance itself if you want to change it after the
    instance is created.
  EOT
}

variable "ssh_cidr" {
  type        = string
  description = <<-EOT
    The CIDR block that defines the source IP range for SSH access
    to the instance.

    This should be set to your public IP address or a range of
    addresses that you want to allow SSH access from. For example,
    1.1.1.1/32 for a single IP.
  EOT
}

# The following variables are used for provider configuration and
# should be set to your Oracle Cloud Infrastructure account details.

variable "tenancy_ocid" {
  type        = string
  description = <<-EOT
    The OCID of the tenancy where the resources will be created.

    This is typically the root compartment of your Oracle Cloud
    Infrastructure account.
  EOT
}

variable "user_ocid" {
  type        = string
  description = <<-EOT
    The OCID of the user who has permissions to create resources
    in the specified compartment.

    This user should have the necessary policies to create
    and manage resources in the specified compartment.
  EOT
}

variable "region" {
  type        = string
  description = <<-EOT
    The region where the resources will be created.

    This should match the region of your Oracle Cloud Infrastructure
    account, such as "ca-toronto-1", "us-ashburn-1", etc.
  EOT
}

variable "fingerprint" {
  type        = string
  description = <<-EOT
    The fingerprint of the private key associated with the user OCID.

    This is used to authenticate the user with Oracle Cloud
    Infrastructure.
  EOT
}

variable "private_key" {
  type        = string
  description = <<-EOT
    The private key used for authentication with Oracle Cloud
    Infrastructure.

    This might not be the same as the key used for SSH access to the
    instance.
  EOT
}

## Outputs

output "oci_core_instance_public_ip" {
  value       = oci_core_instance.instance.public_ip
  description = <<-EOT
    The public IP address of the created instance.

    This can be used to SSH into the instance once it is up and
    running.
  EOT
}

## Local Variables

locals {
  app_name = "oci-freetier-instance"
}

## Providers

provider "oci" {
  tenancy_ocid = var.tenancy_ocid
  user_ocid    = var.user_ocid
  private_key  = var.private_key
  fingerprint  = var.fingerprint
  region       = var.region
}

## Required Providers

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.0"
    }
  }
}

## Resources

# To keep resources organized and easy to clean up, we'll create a
# compartment for our application resources. This is optional, but
# generally recommended for larger projects or when working in a shared
# tenancy.

resource "oci_identity_compartment" "compartment" {
  name           = local.app_name
  description    = "Compartment for ${local.app_name}"
  compartment_id = var.parent_compartment_id
}

# Next, we'll create a virtual cloud network (VCN) to host our
# resources.

resource "oci_core_vcn" "vcn" {
  compartment_id = oci_identity_compartment.compartment.id
  cidr_blocks = [
    "10.0.0.0/16"
  ]
}

# To allow the instance to communicate with the internet, we'll create an
# internet gateway that will route traffic from the VCN to the internet
# and vice versa.

resource "oci_core_internet_gateway" "ig" {
  compartment_id = oci_identity_compartment.compartment.id
  vcn_id         = oci_core_vcn.vcn.id
}

# Now, we'll create a route table to indicate traffic should be routed
# through the internet gateway. Defining the route table alone does not
# do anything; we need to associate it with our subnets to make it
# effective.

resource "oci_core_route_table" "route_table" {
  compartment_id = oci_identity_compartment.compartment.id
  vcn_id         = oci_core_vcn.vcn.id

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.ig.id
  }
}

# We'll need to figure out the availability domains available to our
# tenancy for both subnet and instance creation.

data "oci_identity_availability_domains" "ad" {
  compartment_id = oci_identity_compartment.compartment.id
}

# To ensure all traffic is blocked by default, we can create a security
# list that will be associated with our subnets. We'll end up defining
# a network security group for the instance later.

resource "oci_core_security_list" "security_list" {
  compartment_id = oci_identity_compartment.compartment.id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${local.app_name}-security-list"
}

# Next, we'll create subnets in each availability domain.

resource "oci_core_subnet" "subnet" {
  count               = length(data.oci_identity_availability_domains.ad.availability_domains)
  compartment_id      = oci_identity_compartment.compartment.id
  vcn_id              = oci_core_vcn.vcn.id
  cidr_block          = cidrsubnet(oci_core_vcn.vcn.cidr_blocks[0], 8, count.index)
  availability_domain = data.oci_identity_availability_domains.ad.availability_domains[count.index].name
  security_list_ids   = [oci_core_security_list.security_list.id]
}

# Finally, we'll associate the route table with each subnet to ensure
# that external traffic from our network routes through the internet
# gateway.

resource "oci_core_route_table_attachment" "subnet_route_table_association" {
  count          = length(data.oci_identity_availability_domains.ad.availability_domains)
  subnet_id      = oci_core_subnet.subnet[count.index].id
  route_table_id = oci_core_route_table.route_table.id
}

# To create an instance, we need to specify the operating system image
# to use. We can query the available images to find one that matches
# our desired operating system and version. This is useful for
# ensuring that we are using the latest image available for our
# specified operating system.

data "oci_core_images" "image" {
  compartment_id           = oci_identity_compartment.compartment.id
  operating_system         = var.image_operating_system
  operating_system_version = var.image_operating_system_version
  shape                    = var.instance_shape
}

# By default, no traffic is allowed into the instance.

resource "oci_core_network_security_group" "compute" {
  compartment_id = oci_identity_compartment.compartment.id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${local.app_name}-compute"
}

# To allow SSH access to the instance, we need to create a security
# rule that allows inbound traffic on port 22 (SSH).

resource "oci_core_network_security_group_security_rule" "compute_inbound_ssh" {
  network_security_group_id = oci_core_network_security_group.compute.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = var.ssh_cidr
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      max = 22
      min = 22
    }
  }
}

# To allow updating software on the instance and anything else that
# might be needed, we can create a security rule that allows outbound
# traffic to the internet.

resource "oci_core_network_security_group_security_rule" "compute_outbound_internet" {
  network_security_group_id = oci_core_network_security_group.compute.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

# Now we can create the instance itself.

resource "oci_core_instance" "instance" {
  availability_domain = data.oci_identity_availability_domains.ad.availability_domains[0].name
  compartment_id      = oci_identity_compartment.compartment.id
  shape               = var.instance_shape
  metadata = {
    ssh_authorized_keys = file(var.ssh_authorized_key_path)
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.subnet[0].id
    assign_public_ip = true
    nsg_ids          = [oci_core_network_security_group.compute.id]
  }

  shape_config {
    memory_in_gbs = var.instance_memory_in_gbs
    ocpus         = var.instance_ocpus
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.image.images[0].id
  }
}

