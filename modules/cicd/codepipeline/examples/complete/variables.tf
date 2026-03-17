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

variable "codestar_connection_arn" {
  description = "ARN of the CodeStar connection for GitHub."
  type        = string
}

variable "github_repository" {
  description = "Full repository ID (e.g., org/repo)."
  type        = string
}

variable "branch_name" {
  description = "Branch name to trigger pipeline."
  type        = string
  default     = "main"
}

variable "codebuild_project_name" {
  description = "Name of the CodeBuild project."
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster."
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service."
  type        = string
}
