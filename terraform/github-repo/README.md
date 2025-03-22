# Exercise: Github Repository Management through Terraform

This exercise demonstrates how to Github repositories can be managed through Terraform.

## Notes / Thoughts

- The Github provider does not appear to be the most resilient. It is not uncommon to see errors when running `terraform apply` or `terraform destroy`.
- Not all repository settings are supported by the Github provider. For example, configuring allowed merge methods per branch is not supported.