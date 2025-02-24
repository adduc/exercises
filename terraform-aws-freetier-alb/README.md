# Exercise: Free-tier Load Balancer

This exercise creates a free-tier-eligible load balancer using Terraform.

## Context

I am interested in creating various AWS resources using Terraform, but I want to ensure that they are free-tier eligible. This exercise focuses on creating a load balancer that meets this requirement.

## Notes

This implementation assigns a public IPv4 address to the load balancer. While this is free-tier eligible, only one public IPv4 address is allowed at a time without incurring charges. If you need to create an EC2 instance or anything else that requires a public IPv4 address, consider using the dualstack-without-public-ipv4 ip address type, or a solution that does not require a public IPv4 address (Cloudfront to an internal ALB over a VPC origin).