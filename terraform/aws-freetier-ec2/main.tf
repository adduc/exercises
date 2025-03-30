##
# Exercise: Creating a free-tier-eligible EC2 instance
##

locals {
  app = "freetier-ec2"
}

## Inputs

variable "ssh_key_path" {
  type        = string
  description = <<-EOF
    The path to the SSH public key to add to the default user's
    authorized_keys file. This is used to trust the SSH key for
    access to the EC2 instance.

    @example
    ```
    ssh_key_path = "~/.ssh/id_rsa.pub"
    ```
  EOF
}

variable "allow_ssh_from_cidr" {
  type = string

  description = <<-EOF
    The CIDR block to permit SSH traffic from for access to the EC2
    instance.

    @example
    ```
    allow_ssh_from_cidr = "192.168.1.1/32"
    ```
  EOF
}

## Providers

provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      app = local.app
    }
  }
}

## Required Providers

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

## Resources

# @see https://documentation.ubuntu.com/aws/en/latest/aws-how-to/instances/find-ubuntu-images/
data "aws_ssm_parameter" "ubuntu_24_04_ami" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

# @see https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.app
  cidr = "10.0.0.0/16"

  azs             = ["us-east-2a", "us-east-2b", "us-east-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

# @see https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest
module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = local.app
  description = "Security group for free-tier EC2 instance"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      rule        = "ssh-tcp"
      cidr_blocks = var.allow_ssh_from_cidr
    }
  ]
  egress_rules = ["all-all"]
}

resource "aws_key_pair" "freetier_ec2_key" {
  key_name   = local.app
  public_key = file(var.ssh_key_path)
}

resource "aws_instance" "freetier_ec2" {
  ami           = data.aws_ssm_parameter.ubuntu_24_04_ami.value
  instance_type = "t3.micro"
  key_name      = aws_key_pair.freetier_ec2_key.key_name

  # Networking
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.security_group.security_group_id]
}

## Outputs

output "ec2_public_ip" {
  value = aws_instance.freetier_ec2.public_ip
}
