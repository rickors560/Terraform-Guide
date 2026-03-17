# -----------------------------------------------------------------------------
# VPC Peering Component - Variables
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

variable "requester_vpc_id" {
  description = "VPC ID of the requester (local) VPC"
  type        = string
}

variable "requester_vpc_cidr" {
  description = "CIDR block of the requester VPC"
  type        = string
}

variable "requester_route_table_ids" {
  description = "Route table IDs in the requester VPC to add peering routes"
  type        = list(string)
  default     = []
}

variable "accepter_vpc_id" {
  description = "VPC ID of the accepter (peer) VPC"
  type        = string
}

variable "accepter_vpc_cidr" {
  description = "CIDR block of the accepter VPC"
  type        = string
}

variable "accepter_route_table_ids" {
  description = "Route table IDs in the accepter VPC to add peering routes"
  type        = list(string)
  default     = []
}

variable "peer_account_id" {
  description = "AWS account ID of the peer VPC owner (empty for same-account peering)"
  type        = string
  default     = ""
}

variable "peer_region" {
  description = "AWS region of the peer VPC (empty for same-region peering)"
  type        = string
  default     = ""
}

variable "requester_security_group_ids" {
  description = "Map of security group rules to create on the requester side"
  type = map(object({
    security_group_id = string
    from_port         = number
    to_port           = number
    protocol          = string
  }))
  default = {}
}

variable "accepter_security_group_ids" {
  description = "Map of security group rules to create on the accepter side"
  type = map(object({
    security_group_id = string
    from_port         = number
    to_port           = number
    protocol          = string
  }))
  default = {}
}
