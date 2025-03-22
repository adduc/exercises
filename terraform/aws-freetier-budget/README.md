## Exercise: Creating a zero-spend budget in AWS using Terraform

This exercise shows how to create a zero-spend budget in AWS using
Terraform. It can be used to track costs and notify you when any cost is
incurred.

## Steps

```bash
# create terraform.tfvars file
cp terraform.dist.tfvars terraform.tfvars

# edit terraform.tfvars

# initialize terraform
terraform init

# apply changes
terraform apply
```

## References

- [AWS Budget Documentation](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html)
- [aws_budgets_budget Terraform Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/budgets_budget)
