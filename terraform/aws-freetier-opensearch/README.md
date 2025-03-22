# Exercise: Free-tier OpenSearch cluster using Terraform

This exercise creates a free-tier-eligible OpenSearch cluster using Terraform.

## Instructions

1. Clone the repository
2. Run `terraform init`
3. Run `terraform plan`
4. Run `terraform apply`

## Testing

This exercise does not expose the OpenSearch cluster to the public internet. To develop and test locally, you can use the following steps:

1. Create an EC2 instance in the same VPC as the OpenSearch cluster.
2. Open an SSH connection to the EC2 instance configured to port forward a connection to the OpenSearch cluster.
   ```sh
   sudo ssh -L 443:<opensearch-endpoint>:443 ec2-user@<ec2-public-ip>
   ```
3. Edit /etc/hosts to forward requests for the OpenSearch cluster's endpoint to 127.0.0.1
   ```sh
   sudo vim /etc/hosts
   ```
   Add the following line:
   ```
   127.0.0.1 <opensearch-endpoint>
   ```

At this point, requests to the OpenSearch cluster's endpoint should
connect (by way of the EC2 instance).


## Fine-Grained Access Control

This exercise does not enable fine-grained access control. To enable
fine-grained access control, see the [AWS documentation](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html).
