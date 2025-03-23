# Creating Free-Tier-eligible instance in Oracle Cloud using Terraform

This repository contains a Terraform configuration to create a Free-Tier-eligible instance in Oracle Cloud Infrastructure (OCI).

## Prerequisites

- Terraform
- An Oracle Cloud account with Free Tier eligibility. You can sign up for a free account [here](https://www.oracle.com/cloud/free/).
- An API key for your Oracle Cloud account. You can create one by following the instructions [here](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm).

## Usage

```sh

# Copy the example variables file to terraform.tfvars
# and update it with your own values
cp terraform.dist.tfvars terraform.tfvars

# Initialize Terraform
terraform init

# Apply the configuration
terraform apply

# The `oci_core_instance_public_ip` output will show the public IP
# address of the created instance. You can use this IP to SSH into the instance.

# To destroy the created resources, run:
terraform destroy
```

## Lessons Learned

- Subnets are created with a default security list that allows inbound
SSH traffic and all outbound traffic. This seems less than ideal from a
security perspective.

## Notes

- After running `terraform apply`, it may take a few minutes for the instance to be fully provisioned and accessible.

- After using this configuration to create a Free-Tier-eligible instance, I was able to follow [these instructions](https://alextsang.net/articles/20191006-063049/index.html) to replace the OS with Alpine Linux.