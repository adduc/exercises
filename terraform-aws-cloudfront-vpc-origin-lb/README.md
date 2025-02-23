# Exercise: Using VPC Origin for Cloudfront to ALB communication

This exercise uses Cloudfront's VPC Origin to communicate with an ALB without the need for a public IPv4 address to be assigned to the ALB.

## Context

While provisioning an environment for Wordpress to run within, I noticed
AWS was charging for the use of multiple IPv4 addresses. It turned out that both the ALB and EC2 instance had a public IPv4 address assigned to them. This exercise started as an investigation to see how I could reduce the number of public IPv4 addresses required without any loss of functionality.

## Attempt 1: IPv6 (Failure)

Reading through, Cloudfront, ALB, and EC2 instances all support IPv6 traffic. It'd be easy to make the ALB and EC2 instance IPv6 only, right?
Wrong, ALB and Cloudfront do not support IPv6-only network configurations, and Cloudfront does not support IPv6-only origins.

## Attempt 2: VPC Origin (Success!)

Searching around, it turns out I am not the only individual facing this
issue after AWS started to charge for IPv4 addresses. Someone in a Stack
Overflow thread mentioned Cloudfront's VPC Origin feature. This allows Cloudfront to communicate with an ALB completely within the VPC, without
the need for the ALB to have a public IPv4 address.