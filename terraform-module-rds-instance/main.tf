##
# RDS Instance
#
# This module creates a new RDS instance and related resources.
##


## @todo enable encryption at rest
## @todo enable deletion protection (depending on defaults)
## @todo enable automatic backups (depending on defaults)
## @todo enable point in time recovery (depending on defaults)
## @todo enable performance insights (depending on defaults)
## @todo enable enhanced monitoring (depending on defaults)
## @todo enable auto minor version upgrade (depending on defaults)
## @todo enable deletion protection (depending on defaults)
## @todo create submodule for mariadb (with parameter groups, option groups, audit logging, etc.)



## Locals

locals {
  defaults = {
    free_tier = {
      instance_class      = "db.t4g.micro"
      storage_type        = "gp2"
      storage_size        = 20
      storage_iops        = null
      multi_az            = false
      skip_final_snapshot = true
    }

    prod-small = {
      instance_class      = "db.t4g.micro"
      storage_type        = "gp3"
      storage_size        = 20
      storage_iops        = null
      multi_az            = true
      skip_final_snapshot = false
    }
  }

  default = local.defaults[var.defaults_type]
}

## Resources

resource "aws_db_subnet_group" "this" {
  name       = var.db_name
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "this" {
  name        = var.db_name
  description = "Security group for the RDS instance"
  vpc_id      = var.vpc_id
}

resource "aws_db_instance" "this" {

  # Instance
  db_name                     = var.db_name
  identifier                  = coalesce(var.identifier, var.db_name)
  username                    = var.username
  manage_master_user_password = true

  # Engine
  engine         = var.engine
  engine_version = var.engine_version

  # Compute
  instance_class = coalesce(var.instance_class, local.default.instance_class)

  # Networking
  vpc_security_group_ids = [aws_security_group.this.id]
  db_subnet_group_name   = aws_db_subnet_group.this.name

  # Storage
  allocated_storage     = coalesce(var.storage_size_initial, local.default.storage_size)
  max_allocated_storage = coalesce(var.storage_size_max, local.default.storage_size)
  iops                  = try(coalesce(var.storage_iops, local.default.storage_iops), null)
  storage_type          = coalesce(var.storage_type, local.default.storage_type)

  # Availability
  multi_az = coalesce(var.multi_az, local.default.multi_az)

  # Backup
  skip_final_snapshot = coalesce(var.skip_final_snapshot, local.default.skip_final_snapshot)
}
