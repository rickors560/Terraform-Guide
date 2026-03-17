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
  description = "AMI ID for the EC2 instance"
  type        = string

  validation {
    condition     = can(regex("^ami-[a-f0-9]{8,17}$", var.ami_id))
    error_message = "AMI ID must be a valid format (ami-xxxxxxxx)."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]*\\.[a-z0-9]+$", var.instance_type))
    error_message = "Instance type must be a valid format (e.g., t3.micro)."
  }
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched"
  type        = string

  validation {
    condition     = can(regex("^subnet-[a-f0-9]+$", var.subnet_id))
    error_message = "Subnet ID must be a valid format."
  }
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the instance"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for sg in var.security_group_ids : can(regex("^sg-[a-f0-9]+$", sg))])
    error_message = "All security group IDs must be valid format."
  }
}

variable "key_name" {
  description = "SSH key pair name for the instance"
  type        = string
  default     = null
}

variable "root_volume_type" {
  description = "Root EBS volume type"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2", "st1", "sc1", "standard"], var.root_volume_type)
    error_message = "Volume type must be one of: gp2, gp3, io1, io2, st1, sc1, standard."
  }
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB"
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 16384
    error_message = "Root volume size must be between 8 and 16384 GiB."
  }
}

variable "root_volume_encrypted" {
  description = "Whether the root EBS volume should be encrypted"
  type        = bool
  default     = true
}

variable "root_volume_kms_key_id" {
  description = "KMS key ARN for root EBS volume encryption. Uses AWS managed key if not specified."
  type        = string
  default     = null
}

variable "user_data" {
  description = "User data script for the instance (raw text, will be base64 encoded)"
  type        = string
  default     = null
}

variable "user_data_base64" {
  description = "Base64 encoded user data for the instance"
  type        = string
  default     = null
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile name to attach to the instance"
  type        = string
  default     = null
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring for the instance"
  type        = bool
  default     = false
}

variable "associate_eip" {
  description = "Whether to create and associate an Elastic IP with the instance"
  type        = bool
  default     = false
}

variable "private_ip" {
  description = "Private IP address to associate with the instance"
  type        = string
  default     = null
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with the instance"
  type        = bool
  default     = false
}

variable "disable_api_termination" {
  description = "Enable termination protection for the instance"
  type        = bool
  default     = false
}

variable "ebs_optimized" {
  description = "Whether the instance is EBS optimized"
  type        = bool
  default     = true
}

variable "metadata_http_tokens" {
  description = "Whether IMDSv2 is required. Set to 'required' for IMDSv2."
  type        = string
  default     = "required"

  validation {
    condition     = contains(["optional", "required"], var.metadata_http_tokens)
    error_message = "Metadata HTTP tokens must be 'optional' or 'required'."
  }
}

variable "metadata_http_endpoint" {
  description = "Whether the metadata service is available"
  type        = string
  default     = "enabled"

  validation {
    condition     = contains(["enabled", "disabled"], var.metadata_http_endpoint)
    error_message = "Metadata HTTP endpoint must be 'enabled' or 'disabled'."
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
