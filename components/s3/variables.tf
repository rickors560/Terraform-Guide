###############################################################################
# S3 Component — Variables
###############################################################################

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "bucket_suffix" {
  description = "Suffix appended to the bucket name (e.g., assets, data, logs)"
  type        = string
  default     = "data"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.bucket_suffix))
    error_message = "Bucket suffix must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "force_destroy" {
  description = "Allow Terraform to destroy the bucket even if it contains objects"
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN for SSE-KMS encryption. Leave empty for SSE-S3 (AES256)"
  type        = string
  default     = ""
}

variable "noncurrent_version_expiration_days" {
  description = "Days after which non-current object versions are permanently deleted"
  type        = number
  default     = 90
}

variable "cors_allowed_origins" {
  description = "List of allowed origins for CORS. Leave empty to disable CORS"
  type        = list(string)
  default     = []
}

variable "cors_allowed_methods" {
  description = "List of allowed HTTP methods for CORS"
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "cors_allowed_headers" {
  description = "List of allowed headers for CORS"
  type        = list(string)
  default     = ["*"]
}

variable "cors_expose_headers" {
  description = "List of headers exposed in CORS responses"
  type        = list(string)
  default     = ["ETag"]
}

variable "cors_max_age_seconds" {
  description = "Time in seconds that the browser caches the preflight response"
  type        = number
  default     = 3600
}

variable "logging_target_bucket" {
  description = "S3 bucket name for access logging. Leave empty to disable"
  type        = string
  default     = ""
}
