###############################################################################
# Aurora Component — Variables
###############################################################################

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "vpc_id" {
  description = "VPC ID for the Aurora cluster"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the DB subnet group (minimum 2 AZs)"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect"
  type        = list(string)
  default     = []
}

variable "engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "16.4"
}

variable "instance_class" {
  description = "Aurora instance class"
  type        = string
  default     = "db.r6g.large"
}

variable "instance_count" {
  description = "Number of Aurora instances (writer + readers)"
  type        = number
  default     = 2
}

variable "database_name" {
  description = "Name of the default database"
  type        = string
  default     = "appdb"
}

variable "master_username" {
  description = "Master username"
  type        = string
  default     = "dbadmin"
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption. Leave empty for AWS-managed key"
  type        = string
  default     = ""
}

variable "enhanced_monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0 to disable, 1/5/10/15/30/60)"
  type        = number
  default     = 60
}

variable "enable_autoscaling" {
  description = "Enable auto-scaling for read replicas"
  type        = bool
  default     = false
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of read replicas for auto-scaling"
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of read replicas for auto-scaling"
  type        = number
  default     = 5
}

variable "autoscaling_target_cpu" {
  description = "Target CPU utilization for auto-scaling"
  type        = number
  default     = 70
}
