output "pipeline_id" {
  description = "ID of the CodePipeline."
  value       = aws_codepipeline.this.id
}

output "pipeline_arn" {
  description = "ARN of the CodePipeline."
  value       = aws_codepipeline.this.arn
}

output "pipeline_name" {
  description = "Name of the CodePipeline."
  value       = aws_codepipeline.this.name
}

output "artifact_bucket_id" {
  description = "ID of the artifact S3 bucket."
  value       = var.create_artifact_bucket ? aws_s3_bucket.artifacts[0].id : var.artifact_bucket_name
}

output "artifact_bucket_arn" {
  description = "ARN of the artifact S3 bucket."
  value       = var.create_artifact_bucket ? aws_s3_bucket.artifacts[0].arn : null
}

output "iam_role_arn" {
  description = "ARN of the CodePipeline IAM role."
  value       = var.create_iam_role ? aws_iam_role.codepipeline[0].arn : var.existing_role_arn
}

output "iam_role_name" {
  description = "Name of the CodePipeline IAM role."
  value       = var.create_iam_role ? aws_iam_role.codepipeline[0].name : null
}
