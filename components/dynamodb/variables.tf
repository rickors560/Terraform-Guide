###############################################################################
# DynamoDB Component — Variables
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

variable "table_name" {
  description = "Name suffix for the DynamoDB table"
  type        = string
  default     = "main"
}

variable "billing_mode" {
  description = "Billing mode: PROVISIONED or PAY_PER_REQUEST (on-demand)"
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PROVISIONED", "PAY_PER_REQUEST"], var.billing_mode)
    error_message = "Billing mode must be PROVISIONED or PAY_PER_REQUEST."
  }
}

variable "hash_key" {
  description = "Partition (hash) key attribute name"
  type        = string
  default     = "PK"
}

variable "hash_key_type" {
  description = "Partition key type (S=String, N=Number, B=Binary)"
  type        = string
  default     = "S"
}

variable "range_key" {
  description = "Sort (range) key attribute name"
  type        = string
  default     = "SK"
}

variable "range_key_type" {
  description = "Sort key type (S=String, N=Number, B=Binary)"
  type        = string
  default     = "S"
}

variable "read_capacity" {
  description = "Read capacity units (only for PROVISIONED mode)"
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "Write capacity units (only for PROVISIONED mode)"
  type        = number
  default     = 5
}

variable "gsi_read_capacity" {
  description = "GSI read capacity units (only for PROVISIONED mode)"
  type        = number
  default     = 5
}

variable "gsi_write_capacity" {
  description = "GSI write capacity units (only for PROVISIONED mode)"
  type        = number
  default     = 5
}

variable "ttl_enabled" {
  description = "Enable TTL on the table"
  type        = bool
  default     = true
}

variable "ttl_attribute" {
  description = "Attribute name for TTL"
  type        = string
  default     = "ExpiresAt"
}

variable "pitr_enabled" {
  description = "Enable Point-in-Time Recovery"
  type        = bool
  default     = true
}

variable "stream_enabled" {
  description = "Enable DynamoDB Streams"
  type        = bool
  default     = false
}

variable "stream_view_type" {
  description = "Stream view type: KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES"
  type        = string
  default     = "NEW_AND_OLD_IMAGES"
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption. Leave empty for AWS-owned key"
  type        = string
  default     = ""
}

variable "enable_autoscaling" {
  description = "Enable auto-scaling (only for PROVISIONED mode)"
  type        = bool
  default     = false
}

variable "autoscaling_read_min" {
  description = "Minimum read capacity for auto-scaling"
  type        = number
  default     = 5
}

variable "autoscaling_read_max" {
  description = "Maximum read capacity for auto-scaling"
  type        = number
  default     = 100
}

variable "autoscaling_write_min" {
  description = "Minimum write capacity for auto-scaling"
  type        = number
  default     = 5
}

variable "autoscaling_write_max" {
  description = "Maximum write capacity for auto-scaling"
  type        = number
  default     = 100
}

variable "autoscaling_target_utilization" {
  description = "Target utilization percentage for auto-scaling"
  type        = number
  default     = 70
}
