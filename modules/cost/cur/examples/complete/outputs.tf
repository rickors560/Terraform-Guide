output "report_name" {
  description = "Name of the CUR report."
  value       = module.cur.report_name
}

output "report_arn" {
  description = "ARN of the CUR report."
  value       = module.cur.report_arn
}

output "s3_bucket_id" {
  description = "S3 bucket ID for CUR reports."
  value       = module.cur.s3_bucket_id
}
