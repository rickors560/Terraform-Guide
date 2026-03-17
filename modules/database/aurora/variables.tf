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

variable "engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "16.3"
}

variable "instance_count" {
  description = "Number of cluster instances"
  type        = number
  default     = 2

  validation {
    condition     = var.instance_count >= 1
    error_message = "Must have at least 1 instance."
  }
}

variable "instance_class" {
  description = "Instance class for cluster instances"
  type        = string
  default     = "db.r6g.large"
}

variable "enable_serverless_v2" {
  description = "Enable Aurora Serverless v2 scaling"
  type        = bool
  default     = false
}

variable "serverless_min_capacity" {
  description = "Minimum ACU for Serverless v2"
  type        = number
  default     = 0.5

  validation {
    condition     = var.serverless_min_capacity >= 0.5
    error_message = "Minimum capacity must be at least 0.5 ACU."
  }
}

variable "serverless_max_capacity" {
  description = "Maximum ACU for Serverless v2"
  type        = number
  default     = 16

  validation {
    condition     = var.serverless_max_capacity >= 1
    error_message = "Maximum capacity must be at least 1 ACU."
  }
}

variable "db_name" {
  description = "Name of the default database"
  type        = string
  default     = "appdb"
}

variable "master_username" {
  description = "Master username"
  type        = string
  default     = "dbadmin"
}

variable "manage_master_user_password" {
  description = "Manage master password with Secrets Manager"
  type        = bool
  default     = true
}

variable "master_password" {
  description = "Master password (only used if manage_master_user_password is false)"
  type        = string
  default     = null
  sensitive   = true
}

variable "port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "subnet_ids" {
  description = "Subnet IDs for the DB subnet group"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnet IDs are required."
  }
}

variable "vpc_security_group_ids" {
  description = "Security group IDs"
  type        = list(string)
  default     = []
}

variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ARN for storage encryption"
  type        = string
  default     = null
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "preferred_maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when deleting"
  type        = bool
  default     = false
}

variable "iam_database_authentication_enabled" {
  description = "Enable IAM database authentication"
  type        = bool
  default     = true
}

variable "copy_tags_to_snapshot" {
  description = "Copy tags to snapshots"
  type        = bool
  default     = true
}

variable "enabled_cloudwatch_logs_exports" {
  description = "Log types to export to CloudWatch"
  type        = list(string)
  default     = ["postgresql"]
}

variable "enable_global_database" {
  description = "Whether this cluster is part of a global database"
  type        = bool
  default     = false
}

variable "global_cluster_identifier" {
  description = "Global cluster identifier (required if enable_global_database is true)"
  type        = string
  default     = null
}

variable "cluster_parameters" {
  description = "Cluster parameter group parameters"
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

variable "instance_parameters" {
  description = "Instance parameter group parameters"
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

variable "parameter_group_family" {
  description = "Parameter group family"
  type        = string
  default     = "aurora-postgresql16"
}

variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades for instances"
  type        = bool
  default     = true
}

variable "enable_performance_insights" {
  description = "Enable Performance Insights for instances"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period in days"
  type        = number
  default     = 7
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
