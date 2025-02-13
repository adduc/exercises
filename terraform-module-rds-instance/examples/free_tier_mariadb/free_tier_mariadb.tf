##
# Free-tier eligible MariaDB instance
#
# This example uses the rds instance module to create a free-tier
# eligible MariaDB instance.
#
# @see https://aws.amazon.com/free/
##

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "free-tier-mariadb-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-2a", "us-east-2b", "us-east-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

module "free_tier_mariadb" {
  source = "../../"

  db_name        = "freetiermariadb"
  engine         = "mariadb"
  engine_version = "11.4"
  defaults_type  = "free_tier"
  username       = "free_tier_admin"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
}
