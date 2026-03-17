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

variable "pipeline_name" {
  description = "Name suffix for the CodePipeline."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.pipeline_name))
    error_message = "Pipeline name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "pipeline_type" {
  description = "Type of pipeline. Valid values: V1, V2."
  type        = string
  default     = "V2"

  validation {
    condition     = contains(["V1", "V2"], var.pipeline_type)
    error_message = "Pipeline type must be V1 or V2."
  }
}

variable "execution_mode" {
  description = "Pipeline execution mode. Valid values: QUEUED, SUPERSEDED, PARALLEL."
  type        = string
  default     = "SUPERSEDED"

  validation {
    condition     = contains(["QUEUED", "SUPERSEDED", "PARALLEL"], var.execution_mode)
    error_message = "Execution mode must be QUEUED, SUPERSEDED, or PARALLEL."
  }
}

variable "stages" {
  description = "List of pipeline stage configurations."
  type = list(object({
    name = string
    actions = list(object({
      name             = string
      category         = string
      owner            = string
      provider         = string
      version          = optional(string, "1")
      input_artifacts  = optional(list(string), [])
      output_artifacts = optional(list(string), [])
      run_order        = optional(number, 1)
      region           = optional(string, null)
      namespace        = optional(string, null)
      configuration    = optional(map(string), {})
    }))
  }))

  validation {
    condition     = length(var.stages) >= 2
    error_message = "A pipeline must have at least 2 stages."
  }

  validation {
    condition = alltrue([
      for stage in var.stages : alltrue([
        for action in stage.actions : contains(["Source", "Build", "Test", "Deploy", "Approval", "Invoke"], action.category)
      ])
    ])
    error_message = "Action category must be one of: Source, Build, Test, Deploy, Approval, Invoke."
  }
}

variable "create_artifact_bucket" {
  description = "Whether to create an S3 bucket for pipeline artifacts."
  type        = bool
  default     = true
}

variable "artifact_bucket_name" {
  description = "Name of an existing S3 bucket for artifacts. Required when create_artifact_bucket is false."
  type        = string
  default     = null
}

variable "artifact_bucket_kms_key_arn" {
  description = "ARN of the KMS key for encrypting artifacts in S3."
  type        = string
  default     = null
}

variable "create_iam_role" {
  description = "Whether to create an IAM role for CodePipeline."
  type        = bool
  default     = true
}

variable "existing_role_arn" {
  description = "ARN of an existing IAM role for CodePipeline. Used when create_iam_role is false."
  type        = string
  default     = null
}

variable "additional_iam_policy_arns" {
  description = "List of additional IAM policy ARNs to attach to the CodePipeline role."
  type        = list(string)
  default     = []
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
