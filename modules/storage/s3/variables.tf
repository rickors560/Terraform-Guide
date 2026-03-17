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

variable "bucket_name_suffix" {
  description = "Suffix for the S3 bucket name"
  type        = string

  validation {
    condition     = length(var.bucket_name_suffix) > 0
    error_message = "Bucket name suffix must not be empty."
  }
}

variable "force_destroy" {
  description = "Allow deletion of non-empty bucket"
  type        = bool
  default     = false
}

variable "enable_versioning" {
  description = "Enable bucket versioning"
  type        = bool
  default     = true
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm (aws:kms or AES256)"
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["aws:kms", "AES256"], var.sse_algorithm)
    error_message = "Must be aws:kms or AES256."
  }
}

variable "kms_master_key_id" {
  description = "KMS key ID for SSE-KMS encryption"
  type        = string
  default     = null
}

variable "bucket_key_enabled" {
  description = "Enable S3 Bucket Key for SSE-KMS"
  type        = bool
  default     = true
}

variable "block_public_acls" {
  description = "Block public ACLs"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Block public bucket policies"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Ignore public ACLs"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Restrict public bucket policies"
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules"
  type = list(object({
    id      = string
    enabled = optional(bool, true)
    prefix  = optional(string)
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    expiration_days                    = optional(number)
    noncurrent_version_expiration_days = optional(number)
    noncurrent_version_transitions = optional(list(object({
      noncurrent_days = number
      storage_class   = string
    })), [])
  }))
  default = []
}

variable "cors_rules" {
  description = "List of CORS rules"
  type = list(object({
    allowed_headers = optional(list(string), ["*"])
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string), [])
    max_age_seconds = optional(number, 3600)
  }))
  default = []
}

variable "bucket_policy" {
  description = "Bucket policy JSON document"
  type        = string
  default     = null
}

variable "enable_logging" {
  description = "Enable access logging"
  type        = bool
  default     = false
}

variable "logging_target_bucket" {
  description = "Target bucket for access logs"
  type        = string
  default     = null
}

variable "logging_target_prefix" {
  description = "Prefix for access log objects"
  type        = string
  default     = "logs/"
}

variable "enable_object_lock" {
  description = "Enable S3 Object Lock"
  type        = bool
  default     = false
}

variable "object_lock_mode" {
  description = "Object Lock default retention mode (GOVERNANCE or COMPLIANCE)"
  type        = string
  default     = "GOVERNANCE"

  validation {
    condition     = contains(["GOVERNANCE", "COMPLIANCE"], var.object_lock_mode)
    error_message = "Must be GOVERNANCE or COMPLIANCE."
  }
}

variable "object_lock_days" {
  description = "Object Lock default retention days"
  type        = number
  default     = 30
}

variable "enable_replication" {
  description = "Enable cross-region replication"
  type        = bool
  default     = false
}

variable "replication_destination_bucket_arn" {
  description = "ARN of the destination bucket for replication"
  type        = string
  default     = null
}

variable "replication_role_arn" {
  description = "IAM role ARN for replication"
  type        = string
  default     = null
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
