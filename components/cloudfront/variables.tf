###############################################################################
# CloudFront Component — Variables
###############################################################################

variable "aws_region" {
  description = "AWS region"
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

variable "default_root_object" {
  description = "Default root object (e.g., index.html)"
  type        = string
  default     = "index.html"
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_200"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "Price class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "origin_path" {
  description = "Origin path prefix (e.g., /assets). Leave empty for root"
  type        = string
  default     = ""
}

variable "origin_shield_enabled" {
  description = "Enable Origin Shield for reduced origin load"
  type        = bool
  default     = false
}

variable "domain_aliases" {
  description = "Custom domain aliases (requires ACM certificate)"
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN (us-east-1) for custom domains"
  type        = string
  default     = ""
}

variable "custom_cache_policy" {
  description = "Use a custom cache policy instead of managed CachingOptimized"
  type        = bool
  default     = false
}

variable "default_ttl" {
  description = "Default TTL for custom cache policy (seconds)"
  type        = number
  default     = 86400
}

variable "max_ttl" {
  description = "Maximum TTL for custom cache policy (seconds)"
  type        = number
  default     = 31536000
}

variable "min_ttl" {
  description = "Minimum TTL for custom cache policy (seconds)"
  type        = number
  default     = 0
}

variable "custom_error_page_404" {
  description = "Custom error page path for 404 errors"
  type        = string
  default     = "/404.html"
}

variable "custom_error_page_500" {
  description = "Custom error page path for 500 errors"
  type        = string
  default     = "/500.html"
}

variable "geo_restriction_type" {
  description = "Geo restriction type: whitelist or blacklist"
  type        = string
  default     = "none"
}

variable "geo_restriction_locations" {
  description = "Country codes for geo restriction (ISO 3166-1-alpha-2)"
  type        = list(string)
  default     = []
}

variable "web_acl_arn" {
  description = "WAF Web ACL ARN. Leave empty to skip"
  type        = string
  default     = ""
}
