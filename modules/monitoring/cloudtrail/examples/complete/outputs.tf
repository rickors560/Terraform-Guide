output "trail_arn" {
  description = "ARN of the CloudTrail trail."
  value       = module.cloudtrail.trail_arn
}

output "s3_bucket_id" {
  description = "S3 bucket ID for CloudTrail logs."
  value       = module.cloudtrail.s3_bucket_id
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch Log Group ARN."
  value       = module.cloudtrail.cloudwatch_log_group_arn
}
