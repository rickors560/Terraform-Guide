###############################################################################
# Variables — 02-static-website
###############################################################################

variable "aws_region" {
  description = "AWS region for S3 bucket (CloudFront is global)"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "static-website"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "domain_name" {
  description = "Root domain name (must have a Route53 hosted zone)"
  type        = string
}

variable "site_domain" {
  description = "Full domain for the website (e.g., example.com or app.example.com)"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name for website assets (must be globally unique)"
  type        = string
}

variable "force_destroy_bucket" {
  description = "Allow Terraform to destroy the bucket even if it contains objects"
  type        = bool
  default     = true
}

variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_200"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.cloudfront_price_class)
    error_message = "Must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}
