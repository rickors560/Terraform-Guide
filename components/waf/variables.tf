# -----------------------------------------------------------------------------
# WAF Component - Variables
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

variable "waf_scope" {
  description = "Scope of the WAF Web ACL (REGIONAL for ALB/API Gateway, CLOUDFRONT for CloudFront)"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.waf_scope)
    error_message = "WAF scope must be REGIONAL or CLOUDFRONT."
  }
}

variable "rate_limit" {
  description = "Maximum number of requests from a single IP in a 5-minute window"
  type        = number
  default     = 2000

  validation {
    condition     = var.rate_limit >= 100
    error_message = "Rate limit must be at least 100."
  }
}

variable "blocked_ip_addresses" {
  description = "List of IP addresses/CIDRs to block (must include /32 for single IPs)"
  type        = list(string)
  default     = []
}

variable "allowed_ip_addresses" {
  description = "List of IP addresses/CIDRs to explicitly allow (whitelist)"
  type        = list(string)
  default     = []
}

variable "blocked_country_codes" {
  description = "List of ISO 3166-1 alpha-2 country codes to block"
  type        = list(string)
  default     = []
}

variable "alb_arn" {
  description = "ARN of the ALB to associate with the WAF Web ACL (empty to skip)"
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "Number of days to retain WAF logs in CloudWatch"
  type        = number
  default     = 30
}

variable "blocked_requests_threshold" {
  description = "Threshold for blocked requests alarm (per 5-minute period)"
  type        = number
  default     = 1000
}

variable "rate_limit_alarm_threshold" {
  description = "Threshold for rate-limit alarm (per 5-minute period)"
  type        = number
  default     = 500
}

variable "alarm_sns_topic_arns" {
  description = "List of SNS topic ARNs for alarm notifications"
  type        = list(string)
  default     = []
}
