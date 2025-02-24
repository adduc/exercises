# Exercise: Running Wordpress on AWS (ECS)

This exercise brings up a fully functional Wordpress site on AWS using ECS and RDS.

## Context

Wordpress is both a popular CMS/blogging solution and a unique example of an application that requires persistent storage. As part of my efforts to create resources within AWS' free tier, I wanted to create a Wordpress site that would be free to run.

## Architecture

Cloudfront -> ALB -> ECS (backed by EC2 instance) -> RDS (MariaDB)
