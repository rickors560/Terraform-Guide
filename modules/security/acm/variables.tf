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

variable "domain_name" {
  description = "Primary domain name for the certificate."
  type        = string

  validation {
    condition     = can(regex("^[*a-z0-9][a-z0-9.-]+[a-z0-9]$", var.domain_name))
    error_message = "Domain name must be a valid domain or wildcard domain."
  }
}

variable "subject_alternative_names" {
  description = "List of subject alternative names for the certificate."
  type        = list(string)
  default     = []
}

variable "zone_id" {
  description = "Route53 hosted zone ID for DNS validation."
  type        = string

  validation {
    condition     = can(regex("^Z[A-Z0-9]+$", var.zone_id))
    error_message = "Zone ID must be a valid Route53 hosted zone ID."
  }
}

variable "validation_method" {
  description = "Validation method for the certificate (DNS or EMAIL)."
  type        = string
  default     = "DNS"

  validation {
    condition     = contains(["DNS", "EMAIL"], var.validation_method)
    error_message = "Validation method must be DNS or EMAIL."
  }
}

variable "wait_for_validation" {
  description = "Whether to wait for the certificate to be validated."
  type        = bool
  default     = true
}

variable "validation_timeout" {
  description = "Timeout for certificate validation."
  type        = string
  default     = "45m"
}

variable "key_algorithm" {
  description = "Algorithm for the certificate key pair."
  type        = string
  default     = "RSA_2048"

  validation {
    condition     = contains(["RSA_2048", "EC_prime256v1", "EC_secp384r1"], var.key_algorithm)
    error_message = "Key algorithm must be RSA_2048, EC_prime256v1, or EC_secp384r1."
  }
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
