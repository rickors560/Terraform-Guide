###############################################################################
# S3 Component — Outputs
###############################################################################

output "bucket_id" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.main.arn
}

output "bucket_domain_name" {
  description = "Bucket domain name (e.g., bucket.s3.amazonaws.com)"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the bucket"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

output "bucket_region" {
  description = "AWS region of the bucket"
  value       = aws_s3_bucket.main.region
}

output "versioning_status" {
  description = "Versioning status of the bucket"
  value       = aws_s3_bucket_versioning.main.versioning_configuration[0].status
}
