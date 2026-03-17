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

variable "repository_name_suffix" {
  description = "Suffix for the ECR repository name"
  type        = string

  validation {
    condition     = length(var.repository_name_suffix) > 0
    error_message = "Repository name suffix must not be empty."
  }
}

variable "image_tag_mutability" {
  description = "Image tag mutability setting (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Must be MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Encryption type for the repository (AES256 or KMS)"
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "Must be AES256 or KMS."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption (required when encryption_type is KMS)"
  type        = string
  default     = null
}

variable "force_delete" {
  description = "Delete the repository even if it contains images"
  type        = bool
  default     = false
}

variable "max_tagged_image_count" {
  description = "Maximum number of tagged images to retain"
  type        = number
  default     = 30

  validation {
    condition     = var.max_tagged_image_count >= 1
    error_message = "Must keep at least 1 tagged image."
  }
}

variable "untagged_image_expiry_days" {
  description = "Number of days after which untagged images expire"
  type        = number
  default     = 7

  validation {
    condition     = var.untagged_image_expiry_days >= 1
    error_message = "Must be at least 1 day."
  }
}

variable "cross_account_principal_arns" {
  description = "List of AWS account ARNs or IAM principal ARNs for cross-account access"
  type        = list(string)
  default     = []
}

variable "enable_replication" {
  description = "Whether to enable replication configuration"
  type        = bool
  default     = false
}

variable "replication_destinations" {
  description = "List of replication destinations"
  type = list(object({
    region      = string
    registry_id = string
  }))
  default = []
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
