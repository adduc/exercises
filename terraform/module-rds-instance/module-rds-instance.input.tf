variable "db_name" {
  type        = string
  description = <<-EOT
    The name of the RDS instance.
  EOT
}

variable "username" {
  type        = string
  description = <<-EOT
    The username to use for the administrative user of the RDS instance.
  EOT
}

variable "engine" {
  type        = string
  description = <<-EOT
    The engine of the RDS instance.
  EOT
}

variable "engine_version" {
  type        = string
  description = <<-EOT
    The version of the engine.
  EOT
}

variable "defaults_type" {
  type        = string
  description = <<-EOT
    Which set of defaults to use for the RDS instance. This
    determines the default values for optional variables.
  EOT

  validation {
    condition     = contains(keys(local.defaults), var.defaults_type)
    error_message = "defaults_type must be one of: ${join(", ", keys(local.defaults))}"
  }
}

variable "vpc_id" {
  type        = string
  description = <<-EOT
    The VPC ID of the RDS instance.
  EOT
}

variable "subnet_ids" {
  type        = list(string)
  description = <<-EOT
    The subnet IDs of the RDS instance.
  EOT
}

## Optional Variables with differing defaults (depending on default_name)

variable "instance_class" {
  type        = string
  description = <<-EOT
    The instance class of the RDS instance.
  EOT
  default     = null
  nullable    = true
}

variable "storage_type" {
  type        = string
  description = <<-EOT
    The storage type of the RDS instance.
  EOT
  default     = null
  nullable    = true
}

variable "storage_size_initial" {
  type        = number
  description = <<-EOT
    The initial storage size of the RDS instance.
  EOT
  default     = null
  nullable    = true
}

variable "storage_size_max" {
  type        = number
  description = <<-EOT
    The maximum storage size of the RDS instance.
  EOT
  default     = null
  nullable    = true
}

variable "storage_iops" {
  type        = number
  description = <<-EOT
    The IOPS of the RDS instance.
  EOT
  default     = null
  nullable    = true
}

variable "multi_az" {
  type        = bool
  description = <<-EOT
    Whether to enable multi-AZ.
  EOT
  default     = null
  nullable    = true
}

variable "skip_final_snapshot" {
  type        = bool
  description = <<-EOT
    Whether to skip the final snapshot.
  EOT
  default     = null
  nullable    = true
}

## Optional Variables

variable "identifier" {
  type        = string
  description = <<-EOT
    The identifier of the RDS instance. If not provided, the db_name
    will be used.
  EOT
  default     = null
  nullable    = true
}