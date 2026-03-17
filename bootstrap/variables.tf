variable "project_name" {
  description = "Project name used as a prefix for all resource names."
  type        = string
  default     = "myapp"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.project_name))
    error_message = "Project name must start with a lowercase letter, contain only lowercase alphanumeric characters and hyphens, and be 2–21 characters long."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "region" {
  description = "AWS region for the backend resources."
  type        = string
  default     = "ap-south-1"
}

variable "tags" {
  description = "Additional tags applied to all resources. Must include Team, CostCenter, and Repository."
  type        = map(string)
  default = {
    Team       = "platform"
    CostCenter = "infrastructure"
    Repository = "terraform-guide"
  }
}

variable "state_bucket_force_destroy" {
  description = "Allow the S3 state bucket to be destroyed even if it contains objects. Set to true only for development."
  type        = bool
  default     = false
}
