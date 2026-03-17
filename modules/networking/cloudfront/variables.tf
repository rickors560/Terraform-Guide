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

variable "comment" {
  description = "Comment for the CloudFront distribution."
  type        = string
  default     = ""
}

variable "enabled" {
  description = "Whether the distribution is enabled."
  type        = bool
  default     = true
}

variable "is_ipv6_enabled" {
  description = "Whether IPv6 is enabled."
  type        = bool
  default     = true
}

variable "price_class" {
  description = "CloudFront price class."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "Price class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "default_root_object" {
  description = "Default root object (e.g., index.html)."
  type        = string
  default     = "index.html"
}

variable "aliases" {
  description = "List of custom domain names (CNAMEs) for the distribution."
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for custom domains (must be in us-east-1)."
  type        = string
  default     = null
}

variable "minimum_protocol_version" {
  description = "Minimum TLS protocol version for viewer connections."
  type        = string
  default     = "TLSv1.2_2021"
}

variable "ssl_support_method" {
  description = "How CloudFront serves HTTPS requests (sni-only or vip)."
  type        = string
  default     = "sni-only"

  validation {
    condition     = contains(["sni-only", "vip", "static-ip"], var.ssl_support_method)
    error_message = "SSL support method must be sni-only, vip, or static-ip."
  }
}

variable "s3_origin" {
  description = "S3 origin configuration."
  type = object({
    enabled                = bool
    bucket_regional_domain = string
    origin_id              = optional(string, "s3-origin")
    origin_path            = optional(string, "")
  })
  default = {
    enabled                = false
    bucket_regional_domain = ""
  }
}

variable "custom_origins" {
  description = "List of custom origin configurations."
  type = list(object({
    domain_name         = string
    origin_id           = string
    origin_path         = optional(string, "")
    http_port           = optional(number, 80)
    https_port          = optional(number, 443)
    origin_protocol     = optional(string, "https-only")
    origin_ssl_protocols = optional(list(string), ["TLSv1.2"])
    origin_keepalive_timeout = optional(number, 5)
    origin_read_timeout      = optional(number, 30)
    custom_headers = optional(list(object({
      name  = string
      value = string
    })), [])
  }))
  default = []
}

variable "default_cache_behavior" {
  description = "Default cache behavior configuration."
  type = object({
    target_origin_id       = string
    viewer_protocol_policy = optional(string, "redirect-to-https")
    allowed_methods        = optional(list(string), ["GET", "HEAD", "OPTIONS"])
    cached_methods         = optional(list(string), ["GET", "HEAD"])
    compress               = optional(bool, true)
    min_ttl                = optional(number, 0)
    default_ttl            = optional(number, 3600)
    max_ttl                = optional(number, 86400)
    cache_policy_id            = optional(string, null)
    origin_request_policy_id   = optional(string, null)
    response_headers_policy_id = optional(string, null)
    forwarded_values = optional(object({
      query_string = optional(bool, false)
      cookies      = optional(string, "none")
      headers      = optional(list(string), [])
    }), null)
  })
}

variable "ordered_cache_behaviors" {
  description = "Ordered list of additional cache behaviors."
  type = list(object({
    path_pattern           = string
    target_origin_id       = string
    viewer_protocol_policy = optional(string, "redirect-to-https")
    allowed_methods        = optional(list(string), ["GET", "HEAD", "OPTIONS"])
    cached_methods         = optional(list(string), ["GET", "HEAD"])
    compress               = optional(bool, true)
    min_ttl                = optional(number, 0)
    default_ttl            = optional(number, 3600)
    max_ttl                = optional(number, 86400)
    cache_policy_id            = optional(string, null)
    origin_request_policy_id   = optional(string, null)
    response_headers_policy_id = optional(string, null)
    forwarded_values = optional(object({
      query_string = optional(bool, false)
      cookies      = optional(string, "none")
      headers      = optional(list(string), [])
    }), null)
  }))
  default = []
}

variable "custom_error_responses" {
  description = "Custom error response configurations."
  type = list(object({
    error_code            = number
    response_code         = optional(number, null)
    response_page_path    = optional(string, null)
    error_caching_min_ttl = optional(number, 10)
  }))
  default = []
}

variable "geo_restriction_type" {
  description = "Geo restriction type (none, whitelist, blacklist)."
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.geo_restriction_type)
    error_message = "Geo restriction type must be none, whitelist, or blacklist."
  }
}

variable "geo_restriction_locations" {
  description = "List of ISO 3166-1 alpha-2 country codes for geo restriction."
  type        = list(string)
  default     = []
}

variable "web_acl_id" {
  description = "WAF Web ACL ID to associate with the distribution."
  type        = string
  default     = null
}

variable "logging_config" {
  description = "Logging configuration for CloudFront."
  type = object({
    enabled         = bool
    bucket          = string
    prefix          = optional(string, "")
    include_cookies = optional(bool, false)
  })
  default = {
    enabled = false
    bucket  = ""
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
