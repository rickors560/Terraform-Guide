# -----------------------------------------------------------------------------
# CloudTrail Component - Outputs
# -----------------------------------------------------------------------------

output "trail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = aws_cloudtrail.main.arn
}

output "trail_name" {
  description = "Name of the CloudTrail trail"
  value       = aws_cloudtrail.main.name
}

output "s3_bucket_id" {
  description = "ID of the S3 bucket storing CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket storing CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for CloudTrail"
  value       = aws_cloudwatch_log_group.cloudtrail.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for CloudTrail"
  value       = aws_cloudwatch_log_group.cloudtrail.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for CloudTrail encryption"
  value       = aws_kms_key.cloudtrail.arn
}

output "unauthorized_api_alarm_arn" {
  description = "ARN of the unauthorized API calls alarm"
  value       = aws_cloudwatch_metric_alarm.unauthorized_api_calls.arn
}

output "root_usage_alarm_arn" {
  description = "ARN of the root account usage alarm"
  value       = aws_cloudwatch_metric_alarm.root_account_usage.arn
}
