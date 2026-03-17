output "bucket_name" {
  description = "S3 bucket name"
  value       = module.s3.bucket_name
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = module.s3.bucket_arn
}
