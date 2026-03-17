variable "aws_region" {
  description = "AWS region to deploy resources."
  type        = string
}

variable "project" {
  description = "Project name."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "ecr_repository_uri" {
  description = "ECR repository URI for Docker images."
  type        = string
}
