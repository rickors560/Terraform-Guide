# -----------------------------------------------------------------------------
# Security Groups Component - Variables
# -----------------------------------------------------------------------------

variable "region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "app_port" {
  description = "Application port (e.g., 8080, 3000)"
  type        = number
  default     = 8080
}

variable "db_port" {
  description = "Database port (e.g., 5432 for PostgreSQL, 3306 for MySQL)"
  type        = number
  default     = 5432
}

variable "cache_port" {
  description = "Cache port (e.g., 6379 for Redis)"
  type        = number
  default     = 6379
}

variable "bastion_security_group_id" {
  description = "Existing bastion security group ID for SSH access rules (empty to skip)"
  type        = string
  default     = ""
}

variable "create_bastion_sg" {
  description = "Whether to create a bastion host security group"
  type        = bool
  default     = false
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed SSH access to the bastion"
  type        = list(string)
  default     = []
}
