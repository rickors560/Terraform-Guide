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

variable "lambda_destination_arn" {
  description = "ARN of the Lambda function for log subscription."
  type        = string
}
