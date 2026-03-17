###############################################################################
# ECR Component — Variables
###############################################################################

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "repository_name" {
  description = "Name of the ECR repository (appended to project_name/)"
  type        = string
  default     = "app"
}

variable "image_tag_mutability" {
  description = "Image tag mutability: MUTABLE or IMMUTABLE"
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Must be MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

variable "enhanced_scanning" {
  description = "Enable enhanced (continuous) scanning via Inspector"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption. Leave empty for AES256"
  type        = string
  default     = ""
}

variable "max_tagged_images" {
  description = "Maximum number of release-tagged images to retain"
  type        = number
  default     = 30
}

variable "max_dev_images" {
  description = "Maximum number of dev/staging-tagged images to retain"
  type        = number
  default     = 10
}

variable "untagged_image_expiry_days" {
  description = "Days after which untagged images are deleted"
  type        = number
  default     = 7
}

variable "cross_account_pull_ids" {
  description = "AWS account IDs allowed to pull images cross-account"
  type        = list(string)
  default     = []
}

variable "enable_pull_through_cache" {
  description = "Enable pull-through cache for ECR Public"
  type        = bool
  default     = false
}
