# -----------------------------------------------------------------------------
# SES Component - Variables
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

variable "domain_name" {
  description = "Domain name for SES identity (e.g., example.com)"
  type        = string
}

variable "route53_zone_name" {
  description = "Route53 hosted zone name for DNS records"
  type        = string
  default     = ""
}

variable "create_route53_records" {
  description = "Whether to create Route53 DNS records for SES verification"
  type        = bool
  default     = false
}

variable "dmarc_policy" {
  description = "DMARC policy: none, quarantine, or reject"
  type        = string
  default     = "quarantine"

  validation {
    condition     = contains(["none", "quarantine", "reject"], var.dmarc_policy)
    error_message = "DMARC policy must be none, quarantine, or reject."
  }
}

variable "dmarc_report_email" {
  description = "Email address for DMARC reports"
  type        = string
  default     = "dmarc@example.com"
}
