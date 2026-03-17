output "project_id" {
  description = "ID of the CodeBuild project."
  value       = aws_codebuild_project.this.id
}

output "project_arn" {
  description = "ARN of the CodeBuild project."
  value       = aws_codebuild_project.this.arn
}

output "project_name" {
  description = "Name of the CodeBuild project."
  value       = aws_codebuild_project.this.name
}

output "iam_role_arn" {
  description = "ARN of the CodeBuild IAM role."
  value       = var.create_iam_role ? aws_iam_role.codebuild[0].arn : var.existing_role_arn
}

output "iam_role_name" {
  description = "Name of the CodeBuild IAM role."
  value       = var.create_iam_role ? aws_iam_role.codebuild[0].name : null
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for build logs."
  value       = var.cloudwatch_logs_enabled ? aws_cloudwatch_log_group.codebuild[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for build logs."
  value       = var.cloudwatch_logs_enabled ? aws_cloudwatch_log_group.codebuild[0].arn : null
}
