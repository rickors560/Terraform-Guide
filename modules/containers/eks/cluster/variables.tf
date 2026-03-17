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

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"

  validation {
    condition     = can(regex("^1\\.[0-9]+$", var.kubernetes_version))
    error_message = "Must be a valid Kubernetes version (e.g., 1.29)."
  }
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS cluster"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnet IDs are required for EKS."
  }
}

variable "endpoint_public_access" {
  description = "Whether the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Whether the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR blocks that can access the EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_security_group_ids" {
  description = "Additional security group IDs to attach to the cluster"
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting Kubernetes secrets"
  type        = string
  default     = null
}

variable "enabled_cluster_log_types" {
  description = "List of EKS cluster log types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  validation {
    condition     = alltrue([for lt in var.enabled_cluster_log_types : contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], lt)])
    error_message = "Log types must be: api, audit, authenticator, controllerManager, scheduler."
  }
}

variable "cluster_log_retention_days" {
  description = "CloudWatch log group retention in days for cluster logs"
  type        = number
  default     = 90

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.cluster_log_retention_days)
    error_message = "Must be a valid CloudWatch log retention period."
  }
}

variable "cluster_addons" {
  description = "Map of cluster addon configurations"
  type = map(object({
    version                  = optional(string)
    resolve_conflicts        = optional(string, "OVERWRITE")
    service_account_role_arn = optional(string)
  }))
  default = {
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      resolve_conflicts = "OVERWRITE"
    }
    aws-ebs-csi-driver = {
      resolve_conflicts = "OVERWRITE"
    }
  }
}

variable "enable_oidc_provider" {
  description = "Whether to create an OIDC provider for IRSA"
  type        = bool
  default     = true
}

variable "service_ipv4_cidr" {
  description = "CIDR block for Kubernetes service IPs"
  type        = string
  default     = null
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
