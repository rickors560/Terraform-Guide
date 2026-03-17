###############################################################################
# ACM Component — Variables
###############################################################################

variable "aws_region" {
  description = "AWS region for the regional certificate"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "domain_name" {
  description = "Primary domain name for the certificate (e.g., example.com)"
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional domain names (SANs) for the certificate"
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for DNS validation. Leave empty for manual validation"
  type        = string
  default     = ""
}

variable "create_cloudfront_certificate" {
  description = "Create an additional certificate in us-east-1 for CloudFront"
  type        = bool
  default     = false
}
