variable "project" {
  description = "Project name used for resource naming and tagging."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "Project name must contain only lowercase alphanumeric characters and hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "uat", "sandbox"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, uat, sandbox."
  }
}

variable "name" {
  description = "Short name for the KMS key (used in alias)."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.name))
    error_message = "KMS key name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "description" {
  description = "Description of the KMS key."
  type        = string
  default     = "Managed by Terraform"
}

variable "key_usage" {
  description = "Intended use of the key (ENCRYPT_DECRYPT or SIGN_VERIFY)."
  type        = string
  default     = "ENCRYPT_DECRYPT"

  validation {
    condition     = contains(["ENCRYPT_DECRYPT", "SIGN_VERIFY", "GENERATE_VERIFY_MAC"], var.key_usage)
    error_message = "Key usage must be ENCRYPT_DECRYPT, SIGN_VERIFY, or GENERATE_VERIFY_MAC."
  }
}

variable "customer_master_key_spec" {
  description = "Specifies the type of KMS key to create."
  type        = string
  default     = "SYMMETRIC_DEFAULT"

  validation {
    condition = contains([
      "SYMMETRIC_DEFAULT",
      "RSA_2048", "RSA_3072", "RSA_4096",
      "ECC_NIST_P256", "ECC_NIST_P384", "ECC_NIST_P521", "ECC_SECG_P256K1",
      "HMAC_224", "HMAC_256", "HMAC_384", "HMAC_512",
    ], var.customer_master_key_spec)
    error_message = "Invalid customer master key spec."
  }
}

variable "enable_key_rotation" {
  description = "Whether to enable automatic key rotation."
  type        = bool
  default     = true
}

variable "rotation_period_in_days" {
  description = "Number of days between automatic key rotations (90-2560)."
  type        = number
  default     = 365

  validation {
    condition     = var.rotation_period_in_days >= 90 && var.rotation_period_in_days <= 2560
    error_message = "Rotation period must be between 90 and 2560 days."
  }
}

variable "multi_region" {
  description = "Whether this is a multi-region key."
  type        = bool
  default     = false
}

variable "deletion_window_in_days" {
  description = "Number of days before key deletion (7-30)."
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "Deletion window must be between 7 and 30 days."
  }
}

variable "key_policy" {
  description = "Custom key policy JSON. If null, uses default policy allowing root account full access."
  type        = string
  default     = null
}

variable "key_administrators" {
  description = "List of IAM ARNs that can administer the key."
  type        = list(string)
  default     = []
}

variable "key_users" {
  description = "List of IAM ARNs that can use the key for cryptographic operations."
  type        = list(string)
  default     = []
}

variable "key_service_users" {
  description = "List of IAM ARNs for services that can use the key via grants."
  type        = list(string)
  default     = []
}

variable "grants" {
  description = "Map of grant configurations for the KMS key."
  type = map(object({
    grantee_principal    = string
    operations           = list(string)
    retiring_principal   = optional(string, null)
    grant_creation_tokens = optional(list(string), null)
    constraints = optional(object({
      encryption_context_equals = optional(map(string), null)
      encryption_context_subset = optional(map(string), null)
    }), null)
  }))
  default = {}
}

variable "aliases" {
  description = "Additional aliases for the KMS key (beyond the default one)."
  type        = list(string)
  default     = []
}

variable "team" {
  description = "Team name for resource tagging."
  type        = string
  default     = "platform"
}

variable "cost_center" {
  description = "Cost center for resource tagging."
  type        = string
  default     = "infrastructure"
}

variable "repository" {
  description = "Repository URL for resource tagging."
  type        = string
  default     = ""
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}
