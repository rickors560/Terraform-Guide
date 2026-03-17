output "trail_arn" {
  description = "ARN of the CloudTrail trail."
  value       = aws_cloudtrail.this.arn
}

output "trail_id" {
  description = "Name of the CloudTrail trail."
  value       = aws_cloudtrail.this.id
}

output "trail_home_region" {
  description = "Home region of the CloudTrail trail."
  value       = aws_cloudtrail.this.home_region
}

output "s3_bucket_id" {
  description = "ID of the S3 bucket used for CloudTrail logs."
  value       = var.create_s3_bucket ? aws_s3_bucket.cloudtrail[0].id : var.s3_bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket used for CloudTrail logs."
  value       = var.create_s3_bucket ? aws_s3_bucket.cloudtrail[0].arn : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group for CloudTrail."
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.cloudtrail[0].arn : null
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for CloudTrail."
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.cloudtrail[0].name : null
}

output "iam_role_arn" {
  description = "ARN of the IAM role used by CloudTrail for CloudWatch Logs."
  value       = var.enable_cloudwatch_logs ? aws_iam_role.cloudtrail_cloudwatch[0].arn : null
}
