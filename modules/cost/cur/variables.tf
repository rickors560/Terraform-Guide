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

variable "report_name" {
  description = "Name suffix for the Cost and Usage Report."
  type        = string
  default     = "cost-usage-report"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.report_name))
    error_message = "Report name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "time_unit" {
  description = "Granularity of the report. Valid values: HOURLY, DAILY, MONTHLY."
  type        = string
  default     = "DAILY"

  validation {
    condition     = contains(["HOURLY", "DAILY", "MONTHLY"], var.time_unit)
    error_message = "Time unit must be HOURLY, DAILY, or MONTHLY."
  }
}

variable "format" {
  description = "Format for the report. Valid values: textORcsv, Parquet."
  type        = string
  default     = "Parquet"

  validation {
    condition     = contains(["textORcsv", "Parquet"], var.format)
    error_message = "Format must be textORcsv or Parquet."
  }
}

variable "compression" {
  description = "Compression format. Valid values: GZIP, ZIP, Parquet."
  type        = string
  default     = "Parquet"

  validation {
    condition     = contains(["GZIP", "ZIP", "Parquet"], var.compression)
    error_message = "Compression must be GZIP, ZIP, or Parquet."
  }
}

variable "additional_schema_elements" {
  description = "List of additional schema elements. Valid values: RESOURCES, SPLIT_COST_ALLOCATION_DATA."
  type        = list(string)
  default     = ["RESOURCES"]

  validation {
    condition = alltrue([
      for elem in var.additional_schema_elements : contains(["RESOURCES", "SPLIT_COST_ALLOCATION_DATA"], elem)
    ])
    error_message = "Additional schema elements must be RESOURCES or SPLIT_COST_ALLOCATION_DATA."
  }
}

variable "additional_artifacts" {
  description = "List of additional artifact types. Valid values: REDSHIFT, QUICKSIGHT, ATHENA."
  type        = list(string)
  default     = ["ATHENA"]

  validation {
    condition = alltrue([
      for artifact in var.additional_artifacts : contains(["REDSHIFT", "QUICKSIGHT", "ATHENA"], artifact)
    ])
    error_message = "Additional artifacts must be REDSHIFT, QUICKSIGHT, or ATHENA."
  }
}

variable "report_versioning" {
  description = "Whether to overwrite or create new report versions. Valid values: CREATE_NEW_REPORT, OVERWRITE_REPORT."
  type        = string
  default     = "OVERWRITE_REPORT"

  validation {
    condition     = contains(["CREATE_NEW_REPORT", "OVERWRITE_REPORT"], var.report_versioning)
    error_message = "Report versioning must be CREATE_NEW_REPORT or OVERWRITE_REPORT."
  }
}

variable "refresh_closed_reports" {
  description = "Whether to refresh closed reports when AWS applies refunds, credits, or adjustments."
  type        = bool
  default     = true
}

variable "s3_prefix" {
  description = "S3 key prefix for the report."
  type        = string
  default     = "cur"
}

variable "create_s3_bucket" {
  description = "Whether to create an S3 bucket for CUR reports."
  type        = bool
  default     = true
}

variable "s3_bucket_name" {
  description = "Name of an existing S3 bucket. Required when create_s3_bucket is false."
  type        = string
  default     = ""
}

variable "s3_bucket_force_destroy" {
  description = "Whether to force destroy the S3 bucket on deletion."
  type        = bool
  default     = false
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
