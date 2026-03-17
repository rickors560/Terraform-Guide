variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string

  validation {
    condition     = length(var.project) > 0 && length(var.project) <= 32
    error_message = "Project name must be between 1 and 32 characters."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "uat", "sandbox"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, uat, sandbox."
  }
}

variable "volume_name_suffix" {
  description = "Suffix for the EBS volume name"
  type        = string
  default     = "data"
}

variable "availability_zone" {
  description = "Availability zone for the EBS volume"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9][a-z]$", var.availability_zone))
    error_message = "Must be a valid availability zone (e.g., us-east-1a)."
  }
}

variable "type" {
  description = "EBS volume type"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2", "st1", "sc1", "standard"], var.type)
    error_message = "Must be a valid EBS volume type."
  }
}

variable "size" {
  description = "EBS volume size in GiB"
  type        = number
  default     = 20

  validation {
    condition     = var.size >= 1 && var.size <= 16384
    error_message = "Size must be between 1 and 16384 GiB."
  }
}

variable "iops" {
  description = "IOPS for the volume (applicable for io1, io2, gp3)"
  type        = number
  default     = null
}

variable "throughput" {
  description = "Throughput in MiB/s for gp3 volumes"
  type        = number
  default     = null

  validation {
    condition     = var.throughput == null || (var.throughput >= 125 && var.throughput <= 1000)
    error_message = "Throughput must be between 125 and 1000 MiB/s."
  }
}

variable "encrypted" {
  description = "Enable encryption for the volume"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ARN for encryption"
  type        = string
  default     = null
}

variable "snapshot_id" {
  description = "Snapshot ID to create the volume from"
  type        = string
  default     = null
}

variable "multi_attach_enabled" {
  description = "Enable multi-attach (io1/io2 only)"
  type        = bool
  default     = false
}

variable "final_snapshot" {
  description = "Whether to create a final snapshot before deletion"
  type        = bool
  default     = false
}

variable "team" {
  description = "Team name for resource tagging"
  type        = string
  default     = ""
}

variable "cost_center" {
  description = "Cost center for resource tagging"
  type        = string
  default     = ""
}

variable "repository" {
  description = "Repository URL for resource tagging"
  type        = string
  default     = ""
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
