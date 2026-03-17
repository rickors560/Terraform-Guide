###############################################################################
# Route53 Component — Variables
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

variable "domain_name" {
  description = "Domain name for the hosted zone (e.g., example.com)"
  type        = string
}

variable "a_records" {
  description = "Map of A record names to their configuration"
  type = map(object({
    records = list(string)
    ttl     = number
  }))
  default = {}
}

variable "alias_records" {
  description = "Map of alias A record names to their configuration"
  type = map(object({
    dns_name               = string
    zone_id                = string
    evaluate_target_health = bool
  }))
  default = {}
}

variable "cname_records" {
  description = "Map of CNAME record names to their configuration"
  type = map(object({
    value = string
    ttl   = number
  }))
  default = {}
}

variable "mx_records" {
  description = "MX records (e.g., ['10 mail.example.com', '20 mail2.example.com'])"
  type        = list(string)
  default     = []
}

variable "mx_ttl" {
  description = "TTL for MX records"
  type        = number
  default     = 3600
}

variable "txt_records" {
  description = "Map of TXT record names to their configuration"
  type = map(object({
    values = list(string)
    ttl    = number
  }))
  default = {}
}

variable "caa_records" {
  description = "CAA records (e.g., ['0 issue \"amazon.com\"'])"
  type        = list(string)
  default     = []
}

variable "enable_dnssec" {
  description = "Enable DNSSEC signing for the hosted zone"
  type        = bool
  default     = false
}

variable "health_check_fqdn" {
  description = "FQDN for the health check. Leave empty to skip"
  type        = string
  default     = ""
}

variable "health_check_port" {
  description = "Port for health check"
  type        = number
  default     = 443
}

variable "health_check_type" {
  description = "Health check type: HTTP, HTTPS, TCP"
  type        = string
  default     = "HTTPS"
}

variable "health_check_resource_path" {
  description = "Resource path for HTTP/HTTPS health checks"
  type        = string
  default     = "/"
}

variable "health_check_failure_threshold" {
  description = "Number of consecutive failures before marking unhealthy"
  type        = number
  default     = 3
}

variable "health_check_request_interval" {
  description = "Request interval in seconds (10 or 30)"
  type        = number
  default     = 30
}

variable "health_check_regions" {
  description = "Regions for health check monitoring"
  type        = list(string)
  default     = ["us-east-1", "eu-west-1", "ap-southeast-1"]
}
