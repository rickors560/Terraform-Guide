###############################################################################
# Variables — 04-serverless-api
###############################################################################

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "serverless-api"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}
