# -----------------------------------------------------------------------------
# Secrets Manager Component - Variables
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

variable "recovery_window_in_days" {
  description = "Number of days Secrets Manager waits before permanently deleting a secret (0 for immediate, 7-30)"
  type        = number
  default     = 30

  validation {
    condition     = var.recovery_window_in_days == 0 || (var.recovery_window_in_days >= 7 && var.recovery_window_in_days <= 30)
    error_message = "Recovery window must be 0 (immediate) or between 7 and 30 days."
  }
}

# Database credential variables
variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  default     = "CHANGE_ME_BEFORE_APPLY"
  sensitive   = true
}

variable "db_engine" {
  description = "Database engine type"
  type        = string
  default     = "postgresql"
}

variable "db_host" {
  description = "Database host endpoint"
  type        = string
  default     = "localhost"
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

# API key variables
variable "api_key" {
  description = "API key value"
  type        = string
  default     = "CHANGE_ME_BEFORE_APPLY"
  sensitive   = true
}

variable "api_secret" {
  description = "API secret value"
  type        = string
  default     = "CHANGE_ME_BEFORE_APPLY"
  sensitive   = true
}

# Application config variables
variable "jwt_secret" {
  description = "JWT signing secret"
  type        = string
  default     = "CHANGE_ME_BEFORE_APPLY"
  sensitive   = true
}

variable "encryption_key" {
  description = "Application-level encryption key"
  type        = string
  default     = "CHANGE_ME_BEFORE_APPLY"
  sensitive   = true
}

variable "session_secret" {
  description = "Session signing secret"
  type        = string
  default     = "CHANGE_ME_BEFORE_APPLY"
  sensitive   = true
}

# Rotation configuration
variable "enable_rotation" {
  description = "Whether to enable automatic secret rotation"
  type        = bool
  default     = false
}

variable "rotation_days" {
  description = "Number of days between automatic secret rotations"
  type        = number
  default     = 30
}

# Cross-account access
variable "cross_account_ids" {
  description = "AWS account IDs allowed cross-account secret access"
  type        = list(string)
  default     = []
}
