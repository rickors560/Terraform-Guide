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

variable "name" {
  description = "Name suffix for the SQS queue."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.name))
    error_message = "Queue name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "fifo_queue" {
  description = "Whether to create a FIFO queue."
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enable content-based deduplication for FIFO queues."
  type        = bool
  default     = false
}

variable "deduplication_scope" {
  description = "Deduplication scope for FIFO queues. Valid values: messageGroup, queue."
  type        = string
  default     = null

  validation {
    condition     = var.deduplication_scope == null || contains(["messageGroup", "queue"], var.deduplication_scope)
    error_message = "Deduplication scope must be messageGroup or queue."
  }
}

variable "fifo_throughput_limit" {
  description = "FIFO throughput limit. Valid values: perQueue, perMessageGroupId."
  type        = string
  default     = null

  validation {
    condition     = var.fifo_throughput_limit == null || contains(["perQueue", "perMessageGroupId"], var.fifo_throughput_limit)
    error_message = "FIFO throughput limit must be perQueue or perMessageGroupId."
  }
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout for the queue in seconds (0-43200)."
  type        = number
  default     = 30

  validation {
    condition     = var.visibility_timeout_seconds >= 0 && var.visibility_timeout_seconds <= 43200
    error_message = "Visibility timeout must be between 0 and 43200 seconds."
  }
}

variable "message_retention_seconds" {
  description = "Message retention period in seconds (60-1209600)."
  type        = number
  default     = 345600

  validation {
    condition     = var.message_retention_seconds >= 60 && var.message_retention_seconds <= 1209600
    error_message = "Message retention must be between 60 and 1209600 seconds."
  }
}

variable "max_message_size" {
  description = "Maximum message size in bytes (1024-262144)."
  type        = number
  default     = 262144

  validation {
    condition     = var.max_message_size >= 1024 && var.max_message_size <= 262144
    error_message = "Max message size must be between 1024 and 262144 bytes."
  }
}

variable "delay_seconds" {
  description = "Delay for messages in the queue in seconds (0-900)."
  type        = number
  default     = 0

  validation {
    condition     = var.delay_seconds >= 0 && var.delay_seconds <= 900
    error_message = "Delay must be between 0 and 900 seconds."
  }
}

variable "receive_wait_time_seconds" {
  description = "Wait time for ReceiveMessage calls (long polling) in seconds (0-20)."
  type        = number
  default     = 0

  validation {
    condition     = var.receive_wait_time_seconds >= 0 && var.receive_wait_time_seconds <= 20
    error_message = "Receive wait time must be between 0 and 20 seconds."
  }
}

variable "kms_master_key_id" {
  description = "KMS key ID for server-side encryption. Use 'alias/aws/sqs' for AWS managed key."
  type        = string
  default     = null
}

variable "kms_data_key_reuse_period_seconds" {
  description = "Length of time in seconds for which SQS can reuse a data key (60-86400)."
  type        = number
  default     = 300

  validation {
    condition     = var.kms_data_key_reuse_period_seconds >= 60 && var.kms_data_key_reuse_period_seconds <= 86400
    error_message = "KMS data key reuse period must be between 60 and 86400 seconds."
  }
}

variable "sqs_managed_sse_enabled" {
  description = "Enable SQS-managed server-side encryption (SSE-SQS). Mutually exclusive with kms_master_key_id."
  type        = bool
  default     = true
}

variable "policy" {
  description = "SQS queue access policy JSON string."
  type        = string
  default     = null
}

variable "create_dlq" {
  description = "Whether to create a dead-letter queue."
  type        = bool
  default     = true
}

variable "dlq_max_receive_count" {
  description = "Number of times a message can be received before being sent to the DLQ."
  type        = number
  default     = 3

  validation {
    condition     = var.dlq_max_receive_count >= 1 && var.dlq_max_receive_count <= 1000
    error_message = "DLQ max receive count must be between 1 and 1000."
  }
}

variable "dlq_message_retention_seconds" {
  description = "Message retention period for the DLQ in seconds."
  type        = number
  default     = 1209600

  validation {
    condition     = var.dlq_message_retention_seconds >= 60 && var.dlq_message_retention_seconds <= 1209600
    error_message = "DLQ message retention must be between 60 and 1209600 seconds."
  }
}

variable "existing_dlq_arn" {
  description = "ARN of an existing dead-letter queue. Used when create_dlq is false."
  type        = string
  default     = null
}

variable "redrive_allow_policy" {
  description = "JSON policy to define which source queues can use this queue as a DLQ."
  type        = string
  default     = null
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
