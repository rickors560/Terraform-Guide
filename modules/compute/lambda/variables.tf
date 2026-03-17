variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string

  validation {
    condition     = length(var.project) > 0 && length(var.project) <= 32
    error_message = "Project name must be between 1 and 32 characters."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "uat", "sandbox"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, uat, sandbox."
  }
}

variable "function_name_suffix" {
  description = "Suffix appended to the function name after the name prefix"
  type        = string

  validation {
    condition     = length(var.function_name_suffix) > 0
    error_message = "Function name suffix must not be empty."
  }
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = ""
}

variable "runtime" {
  description = "Lambda runtime identifier"
  type        = string

  validation {
    condition     = can(regex("^(python3\\.[0-9]+|nodejs[0-9]+\\.x|java[0-9]+|dotnet[0-9]+|go1\\.x|ruby[0-9]+\\.[0-9]+|provided\\.al2(023)?)$", var.runtime))
    error_message = "Must be a valid Lambda runtime."
  }
}

variable "handler" {
  description = "Lambda function handler"
  type        = string

  validation {
    condition     = length(var.handler) > 0
    error_message = "Handler must not be empty."
  }
}

variable "memory_size" {
  description = "Amount of memory (MB) for the Lambda function"
  type        = number
  default     = 128

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "Memory size must be between 128 and 10240 MB."
  }
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "Timeout must be between 1 and 900 seconds."
  }
}

variable "filename" {
  description = "Path to the Lambda deployment package (zip file)"
  type        = string
  default     = null
}

variable "source_code_hash" {
  description = "Base64-encoded SHA256 hash of the deployment package"
  type        = string
  default     = null
}

variable "s3_bucket" {
  description = "S3 bucket containing the Lambda deployment package"
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 key of the Lambda deployment package"
  type        = string
  default     = null
}

variable "s3_object_version" {
  description = "S3 object version of the Lambda deployment package"
  type        = string
  default     = null
}

variable "environment_variables" {
  description = "Map of environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "vpc_subnet_ids" {
  description = "Subnet IDs for VPC configuration (optional)"
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "Security group IDs for VPC configuration (optional)"
  type        = list(string)
  default     = []
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrent executions. -1 for unreserved."
  type        = number
  default     = -1

  validation {
    condition     = var.reserved_concurrent_executions >= -1
    error_message = "Must be -1 or greater."
  }
}

variable "layers" {
  description = "List of Lambda layer ARNs"
  type        = list(string)
  default     = []
}

variable "dead_letter_target_arn" {
  description = "ARN of SQS queue or SNS topic for dead letter queue"
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days"
  type        = number
  default     = 14

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "Must be a valid CloudWatch log retention period."
  }
}

variable "log_kms_key_id" {
  description = "KMS key ARN for CloudWatch log group encryption"
  type        = string
  default     = null
}

variable "architectures" {
  description = "Instruction set architecture (x86_64 or arm64)"
  type        = list(string)
  default     = ["x86_64"]

  validation {
    condition     = length(var.architectures) == 1 && contains(["x86_64", "arm64"], var.architectures[0])
    error_message = "Architecture must be x86_64 or arm64."
  }
}

variable "publish" {
  description = "Whether to publish a new Lambda version"
  type        = bool
  default     = false
}

variable "additional_iam_policies" {
  description = "List of additional IAM policy ARNs to attach to the Lambda execution role"
  type        = list(string)
  default     = []
}

variable "event_source_mapping" {
  description = "Event source mapping configuration"
  type = list(object({
    event_source_arn                   = string
    batch_size                         = optional(number, 10)
    starting_position                  = optional(string)
    enabled                            = optional(bool, true)
    maximum_batching_window_in_seconds = optional(number)
    maximum_retry_attempts             = optional(number)
    bisect_batch_on_function_error     = optional(bool)
  }))
  default = []
}

variable "team" {
  description = "Team name for resource tagging"
  type        = string
  default     = ""
}

variable "cost_center" {
  description = "Cost center for resource tagging"
  type        = string
  default     = ""
}

variable "repository" {
  description = "Repository URL for resource tagging"
  type        = string
  default     = ""
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
