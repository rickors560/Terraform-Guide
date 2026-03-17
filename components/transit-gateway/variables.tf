# -----------------------------------------------------------------------------
# Transit Gateway Component - Variables
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

variable "amazon_side_asn" {
  description = "Amazon side ASN for the Transit Gateway (64512-65534 for 16-bit, or 4200000000-4294967294 for 32-bit)"
  type        = number
  default     = 64512
}

variable "auto_accept_shared_attachments" {
  description = "Whether to auto-accept shared attachments from other accounts"
  type        = bool
  default     = false
}

variable "vpc_attachments" {
  description = "Map of VPC attachments with their configuration"
  type = map(object({
    vpc_id           = string
    subnet_ids       = list(string)
    route_table_type = string  # shared_services, isolated, or egress
  }))
  default = {}

  validation {
    condition = alltrue([
      for v in values(var.vpc_attachments) :
      contains(["shared_services", "isolated", "egress"], v.route_table_type)
    ])
    error_message = "route_table_type must be one of: shared_services, isolated, egress."
  }
}

variable "share_with_organization" {
  description = "Whether to share the Transit Gateway with the entire AWS Organization"
  type        = bool
  default     = false
}

variable "share_with_account_ids" {
  description = "List of AWS account IDs to share the Transit Gateway with (ignored if share_with_organization is true)"
  type        = list(string)
  default     = []
}
