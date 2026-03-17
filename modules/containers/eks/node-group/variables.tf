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

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "node_group_name_suffix" {
  description = "Suffix for the node group name"
  type        = string
  default     = "general"
}

variable "subnet_ids" {
  description = "Subnet IDs for the node group"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "At least one subnet ID is required."
  }
}

variable "instance_types" {
  description = "List of instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "ami_type" {
  description = "AMI type for the node group"
  type        = string
  default     = "AL2_x86_64"

  validation {
    condition     = contains(["AL2_x86_64", "AL2_x86_64_GPU", "AL2_ARM_64", "AL2023_x86_64_STANDARD", "AL2023_ARM_64_STANDARD", "BOTTLEROCKET_ARM_64", "BOTTLEROCKET_x86_64", "CUSTOM"], var.ami_type)
    error_message = "Must be a valid EKS AMI type."
  }
}

variable "capacity_type" {
  description = "Capacity type for the node group (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "Must be ON_DEMAND or SPOT."
  }
}

variable "min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1

  validation {
    condition     = var.min_size >= 0
    error_message = "Minimum size must be >= 0."
  }
}

variable "max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 3

  validation {
    condition     = var.max_size >= 1
    error_message = "Maximum size must be >= 1."
  }
}

variable "desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2

  validation {
    condition     = var.desired_size >= 0
    error_message = "Desired size must be >= 0."
  }
}

variable "disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 50

  validation {
    condition     = var.disk_size >= 20
    error_message = "Disk size must be at least 20 GiB."
  }
}

variable "labels" {
  description = "Kubernetes labels for the nodes"
  type        = map(string)
  default     = {}
}

variable "taints" {
  description = "Kubernetes taints for the nodes"
  type = list(object({
    key    = string
    value  = optional(string)
    effect = string
  }))
  default = []

  validation {
    condition     = alltrue([for t in var.taints : contains(["NO_SCHEDULE", "NO_EXECUTE", "PREFER_NO_SCHEDULE"], t.effect)])
    error_message = "Taint effect must be NO_SCHEDULE, NO_EXECUTE, or PREFER_NO_SCHEDULE."
  }
}

variable "max_unavailable" {
  description = "Maximum number of nodes unavailable during update"
  type        = number
  default     = 1

  validation {
    condition     = var.max_unavailable >= 1
    error_message = "Must be at least 1."
  }
}

variable "max_unavailable_percentage" {
  description = "Maximum percentage of nodes unavailable during update (overrides max_unavailable)"
  type        = number
  default     = null

  validation {
    condition     = var.max_unavailable_percentage == null || (var.max_unavailable_percentage >= 1 && var.max_unavailable_percentage <= 100)
    error_message = "Must be between 1 and 100."
  }
}

variable "ssh_key_name" {
  description = "SSH key pair name for remote access"
  type        = string
  default     = null
}

variable "ssh_security_group_ids" {
  description = "Security group IDs for SSH access"
  type        = list(string)
  default     = []
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
