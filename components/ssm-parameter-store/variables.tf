# -----------------------------------------------------------------------------
# SSM Parameter Store Component - Variables
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

# Application configuration
variable "log_level" {
  description = "Application log level"
  type        = string
  default     = "INFO"

  validation {
    condition     = contains(["DEBUG", "INFO", "WARN", "ERROR"], var.log_level)
    error_message = "Log level must be DEBUG, INFO, WARN, or ERROR."
  }
}

variable "app_port" {
  description = "Application listening port"
  type        = number
  default     = 8080
}

variable "max_connections" {
  description = "Maximum number of concurrent connections"
  type        = number
  default     = 100
}

variable "feature_flags" {
  description = "List of enabled feature flags"
  type        = list(string)
  default     = ["dark-mode", "notifications"]
}

variable "allowed_origins" {
  description = "List of allowed CORS origins"
  type        = list(string)
  default     = ["http://localhost:3000"]
}

# Database configuration
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

variable "db_username" {
  description = "Database username (stored as SecureString)"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "Database password (stored as SecureString)"
  type        = string
  default     = "CHANGE_ME_BEFORE_APPLY"
  sensitive   = true
}

# Cache configuration
variable "cache_host" {
  description = "Cache cluster endpoint"
  type        = string
  default     = "localhost"
}

variable "cache_port" {
  description = "Cache port"
  type        = number
  default     = 6379
}

variable "cache_auth_token" {
  description = "Cache authentication token (stored as SecureString)"
  type        = string
  default     = "CHANGE_ME_BEFORE_APPLY"
  sensitive   = true
}

# External service configuration
variable "external_api_key" {
  description = "External API key (stored as SecureString)"
  type        = string
  default     = "CHANGE_ME_BEFORE_APPLY"
  sensitive   = true
}

variable "external_api_base_url" {
  description = "External API base URL"
  type        = string
  default     = "https://api.example.com/v1"
}
