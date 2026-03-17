output "report_name" {
  description = "Name of the Cost and Usage Report."
  value       = aws_cur_report_definition.this.report_name
}

output "report_arn" {
  description = "ARN of the Cost and Usage Report."
  value       = aws_cur_report_definition.this.arn
}

output "s3_bucket_id" {
  description = "ID of the S3 bucket for CUR reports."
  value       = var.create_s3_bucket ? aws_s3_bucket.cur[0].id : var.s3_bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for CUR reports."
  value       = var.create_s3_bucket ? aws_s3_bucket.cur[0].arn : null
}

output "s3_prefix" {
  description = "S3 prefix for the CUR report files."
  value       = var.s3_prefix
}
