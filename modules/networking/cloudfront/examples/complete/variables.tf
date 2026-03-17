variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "project" {
  description = "Project name."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "aliases" {
  description = "Custom domain names."
  type        = list(string)
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN (us-east-1)."
  type        = string
}

variable "s3_bucket_regional_domain" {
  description = "S3 bucket regional domain name."
  type        = string
}

variable "api_origin_domain" {
  description = "API origin domain name."
  type        = string
}

variable "web_acl_arn" {
  description = "WAF Web ACL ARN."
  type        = string
  default     = null
}

variable "logging_bucket" {
  description = "S3 bucket for CloudFront logs (must include .s3.amazonaws.com)."
  type        = string
}

variable "team" {
  description = "Team name."
  type        = string
  default     = "platform"
}

variable "cost_center" {
  description = "Cost center."
  type        = string
  default     = "infrastructure"
}
