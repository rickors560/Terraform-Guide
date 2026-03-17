# -----------------------------------------------------------------------------
# Cognito Component - Variables
# -----------------------------------------------------------------------------

variable "region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

variable "password_minimum_length" {
  description = "Minimum length for user passwords"
  type        = number
  default     = 12
}

variable "mfa_configuration" {
  description = "MFA configuration: OFF, ON, or OPTIONAL"
  type        = string
  default     = "OPTIONAL"

  validation {
    condition     = contains(["OFF", "ON", "OPTIONAL"], var.mfa_configuration)
    error_message = "MFA configuration must be OFF, ON, or OPTIONAL."
  }
}

variable "advanced_security_mode" {
  description = "Advanced security mode: OFF, AUDIT, or ENFORCED"
  type        = string
  default     = "AUDIT"

  validation {
    condition     = contains(["OFF", "AUDIT", "ENFORCED"], var.advanced_security_mode)
    error_message = "Advanced security mode must be OFF, AUDIT, or ENFORCED."
  }
}

variable "callback_urls" {
  description = "List of allowed callback URLs for the web app client"
  type        = list(string)
  default     = ["http://localhost:3000/callback"]
}

variable "logout_urls" {
  description = "List of allowed logout URLs for the web app client"
  type        = list(string)
  default     = ["http://localhost:3000"]
}

variable "access_token_validity_hours" {
  description = "Access token validity in hours"
  type        = number
  default     = 1
}

variable "id_token_validity_hours" {
  description = "ID token validity in hours"
  type        = number
  default     = 1
}

variable "refresh_token_validity_days" {
  description = "Refresh token validity in days"
  type        = number
  default     = 30
}

variable "pre_sign_up_lambda_arn" {
  description = "ARN of the pre sign-up Lambda trigger (empty to skip)"
  type        = string
  default     = ""
}

variable "post_confirmation_lambda_arn" {
  description = "ARN of the post confirmation Lambda trigger (empty to skip)"
  type        = string
  default     = ""
}

variable "pre_token_generation_lambda_arn" {
  description = "ARN of the pre token generation Lambda trigger (empty to skip)"
  type        = string
  default     = ""
}
