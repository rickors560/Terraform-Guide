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

variable "ami_id" {
  description = "AMI ID for the launch template"
  type        = string

  validation {
    condition     = can(regex("^ami-[a-f0-9]{8,17}$", var.ami_id))
    error_message = "AMI ID must be a valid format."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = null
}

variable "security_group_ids" {
  description = "List of security group IDs for network interfaces"
  type        = list(string)
  default     = []
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with network interfaces"
  type        = bool
  default     = false
}

variable "block_device_mappings" {
  description = "List of block device mappings for the launch template"
  type = list(object({
    device_name = string
    ebs = object({
      volume_size           = number
      volume_type           = string
      encrypted             = bool
      kms_key_id            = optional(string)
      delete_on_termination = optional(bool, true)
      iops                  = optional(number)
      throughput            = optional(number)
      snapshot_id           = optional(string)
    })
  }))
  default = [
    {
      device_name = "/dev/xvda"
      ebs = {
        volume_size           = 20
        volume_type           = "gp3"
        encrypted             = true
        delete_on_termination = true
      }
    }
  ]
}

variable "user_data_base64" {
  description = "Base64 encoded user data"
  type        = string
  default     = null
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile name"
  type        = string
  default     = null
}

variable "iam_instance_profile_arn" {
  description = "IAM instance profile ARN (takes precedence over name)"
  type        = string
  default     = null
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = false
}

variable "metadata_http_tokens" {
  description = "Whether IMDSv2 is required"
  type        = string
  default     = "required"

  validation {
    condition     = contains(["optional", "required"], var.metadata_http_tokens)
    error_message = "Must be 'optional' or 'required'."
  }
}

variable "metadata_http_endpoint" {
  description = "Whether the metadata service is available"
  type        = string
  default     = "enabled"

  validation {
    condition     = contains(["enabled", "disabled"], var.metadata_http_endpoint)
    error_message = "Must be 'enabled' or 'disabled'."
  }
}

variable "metadata_http_put_response_hop_limit" {
  description = "Desired HTTP PUT response hop limit for instance metadata requests"
  type        = number
  default     = 2

  validation {
    condition     = var.metadata_http_put_response_hop_limit >= 1 && var.metadata_http_put_response_hop_limit <= 64
    error_message = "Hop limit must be between 1 and 64."
  }
}

variable "ebs_optimized" {
  description = "Whether the instance is EBS optimized"
  type        = bool
  default     = true
}

variable "disable_api_termination" {
  description = "Enable termination protection"
  type        = bool
  default     = false
}

variable "update_default_version" {
  description = "Whether to update the default version of the launch template"
  type        = bool
  default     = true
}

variable "tag_specifications_resource_types" {
  description = "Resource types to tag on launch"
  type        = list(string)
  default     = ["instance", "volume"]

  validation {
    condition     = alltrue([for rt in var.tag_specifications_resource_types : contains(["instance", "volume", "network-interface", "spot-instances-request"], rt)])
    error_message = "Resource types must be one of: instance, volume, network-interface, spot-instances-request."
  }
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
