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

variable "build_project_name" {
  description = "Name suffix for the CodeBuild project."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.build_project_name))
    error_message = "Build project name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "description" {
  description = "Description of the CodeBuild project."
  type        = string
  default     = ""
}

variable "build_timeout" {
  description = "Build timeout in minutes (5-480)."
  type        = number
  default     = 60

  validation {
    condition     = var.build_timeout >= 5 && var.build_timeout <= 480
    error_message = "Build timeout must be between 5 and 480 minutes."
  }
}

variable "queued_timeout" {
  description = "Queue timeout in minutes (5-480)."
  type        = number
  default     = 480

  validation {
    condition     = var.queued_timeout >= 5 && var.queued_timeout <= 480
    error_message = "Queued timeout must be between 5 and 480 minutes."
  }
}

variable "concurrent_build_limit" {
  description = "Maximum number of concurrent builds. Set to null for no limit."
  type        = number
  default     = null
}

################################################################################
# Environment Configuration
################################################################################

variable "compute_type" {
  description = "Compute type for the build environment."
  type        = string
  default     = "BUILD_GENERAL1_SMALL"

  validation {
    condition = contains([
      "BUILD_GENERAL1_SMALL", "BUILD_GENERAL1_MEDIUM", "BUILD_GENERAL1_LARGE",
      "BUILD_GENERAL1_2XLARGE", "BUILD_LAMBDA_1GB", "BUILD_LAMBDA_2GB",
      "BUILD_LAMBDA_4GB", "BUILD_LAMBDA_8GB", "BUILD_LAMBDA_10GB"
    ], var.compute_type)
    error_message = "Compute type must be a valid CodeBuild compute type."
  }
}

variable "image" {
  description = "Docker image for the build environment."
  type        = string
  default     = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
}

variable "environment_type" {
  description = "Type of build environment."
  type        = string
  default     = "LINUX_CONTAINER"

  validation {
    condition = contains([
      "LINUX_CONTAINER", "LINUX_GPU_CONTAINER", "WINDOWS_CONTAINER",
      "WINDOWS_SERVER_2019_CONTAINER", "ARM_CONTAINER", "LINUX_LAMBDA_CONTAINER",
      "ARM_LAMBDA_CONTAINER"
    ], var.environment_type)
    error_message = "Environment type must be a valid CodeBuild environment type."
  }
}

variable "privileged_mode" {
  description = "Whether to enable running Docker daemon inside the build container."
  type        = bool
  default     = false
}

variable "image_pull_credentials_type" {
  description = "Type of credentials used to pull the build image. Valid values: CODEBUILD, SERVICE_ROLE."
  type        = string
  default     = "CODEBUILD"

  validation {
    condition     = contains(["CODEBUILD", "SERVICE_ROLE"], var.image_pull_credentials_type)
    error_message = "Image pull credentials type must be CODEBUILD or SERVICE_ROLE."
  }
}

variable "certificate" {
  description = "ARN of the S3 bucket containing the certificate for the build project."
  type        = string
  default     = null
}

################################################################################
# Source Configuration
################################################################################

variable "source_type" {
  description = "Type of source provider."
  type        = string
  default     = "CODEPIPELINE"

  validation {
    condition = contains([
      "CODECOMMIT", "CODEPIPELINE", "GITHUB", "GITHUB_ENTERPRISE",
      "BITBUCKET", "S3", "NO_SOURCE"
    ], var.source_type)
    error_message = "Source type must be a valid CodeBuild source type."
  }
}

variable "source_location" {
  description = "Source location URL or S3 bucket/key. Not required for CODEPIPELINE source."
  type        = string
  default     = null
}

variable "source_version" {
  description = "Version of the source (branch, tag, commit ID)."
  type        = string
  default     = null
}

variable "git_clone_depth" {
  description = "Git clone depth (0 for full clone)."
  type        = number
  default     = 1
}

variable "buildspec" {
  description = "Buildspec file content (inline) or path to buildspec file."
  type        = string
  default     = null
}

variable "report_build_status" {
  description = "Whether to report build status to source provider."
  type        = bool
  default     = false
}

################################################################################
# Artifacts Configuration
################################################################################

variable "artifacts_type" {
  description = "Type of build artifacts."
  type        = string
  default     = "CODEPIPELINE"

  validation {
    condition     = contains(["CODEPIPELINE", "NO_ARTIFACTS", "S3"], var.artifacts_type)
    error_message = "Artifacts type must be CODEPIPELINE, NO_ARTIFACTS, or S3."
  }
}

variable "artifacts_location" {
  description = "S3 bucket name for artifacts. Required when artifacts_type is S3."
  type        = string
  default     = null
}

variable "artifacts_name" {
  description = "Name of the build artifacts."
  type        = string
  default     = null
}

variable "artifacts_packaging" {
  description = "Packaging type for artifacts. Valid values: NONE, ZIP."
  type        = string
  default     = null

  validation {
    condition     = var.artifacts_packaging == null || contains(["NONE", "ZIP"], var.artifacts_packaging)
    error_message = "Artifacts packaging must be NONE or ZIP."
  }
}

variable "artifacts_encryption_disabled" {
  description = "Whether to disable encryption on artifacts."
  type        = bool
  default     = false
}

################################################################################
# VPC Configuration
################################################################################

variable "vpc_config" {
  description = "VPC configuration for the CodeBuild project."
  type = object({
    vpc_id             = string
    subnets            = list(string)
    security_group_ids = list(string)
  })
  default = null
}

################################################################################
# Cache Configuration
################################################################################

variable "cache_type" {
  description = "Type of build cache. Valid values: NO_CACHE, LOCAL, S3."
  type        = string
  default     = "NO_CACHE"

  validation {
    condition     = contains(["NO_CACHE", "LOCAL", "S3"], var.cache_type)
    error_message = "Cache type must be NO_CACHE, LOCAL, or S3."
  }
}

variable "cache_location" {
  description = "S3 bucket location for S3 cache type."
  type        = string
  default     = null
}

variable "cache_modes" {
  description = "Local cache modes. Valid values: LOCAL_SOURCE_CACHE, LOCAL_DOCKER_LAYER_CACHE, LOCAL_CUSTOM_CACHE."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for mode in var.cache_modes : contains(
        ["LOCAL_SOURCE_CACHE", "LOCAL_DOCKER_LAYER_CACHE", "LOCAL_CUSTOM_CACHE"],
        mode
      )
    ])
    error_message = "Cache modes must be LOCAL_SOURCE_CACHE, LOCAL_DOCKER_LAYER_CACHE, or LOCAL_CUSTOM_CACHE."
  }
}

################################################################################
# Logging Configuration
################################################################################

variable "cloudwatch_logs_enabled" {
  description = "Whether to enable CloudWatch Logs for the build."
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_name" {
  description = "CloudWatch Logs group name. Defaults to /aws/codebuild/{project_name}."
  type        = string
  default     = null
}

variable "cloudwatch_log_stream_name" {
  description = "CloudWatch Logs stream name."
  type        = string
  default     = null
}

variable "s3_logs_enabled" {
  description = "Whether to enable S3 logs."
  type        = bool
  default     = false
}

variable "s3_logs_location" {
  description = "S3 location for build logs (bucket/prefix)."
  type        = string
  default     = null
}

variable "s3_logs_encryption_disabled" {
  description = "Whether to disable encryption on S3 logs."
  type        = bool
  default     = false
}

################################################################################
# Environment Variables
################################################################################

variable "environment_variables" {
  description = "Map of plaintext environment variables for the build."
  type        = map(string)
  default     = {}
}

variable "environment_variables_ssm" {
  description = "Map of SSM Parameter Store environment variables (key = env var name, value = SSM parameter name)."
  type        = map(string)
  default     = {}
}

variable "environment_variables_secrets_manager" {
  description = "Map of Secrets Manager environment variables (key = env var name, value = secret ARN or name)."
  type        = map(string)
  default     = {}
}

################################################################################
# IAM Configuration
################################################################################

variable "create_iam_role" {
  description = "Whether to create an IAM role for CodeBuild."
  type        = bool
  default     = true
}

variable "existing_role_arn" {
  description = "ARN of an existing IAM role for CodeBuild. Used when create_iam_role is false."
  type        = string
  default     = null
}

variable "additional_iam_policy_arns" {
  description = "List of additional IAM policy ARNs to attach to the CodeBuild role."
  type        = list(string)
  default     = []
}

variable "additional_iam_statements" {
  description = "Additional IAM policy statements for the CodeBuild role."
  type = list(object({
    sid       = optional(string, null)
    effect    = string
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

################################################################################
# Tagging
################################################################################

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
