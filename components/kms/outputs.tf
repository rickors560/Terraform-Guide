# -----------------------------------------------------------------------------
# KMS Component - Outputs
# -----------------------------------------------------------------------------

output "general_key_id" {
  description = "ID of the general-purpose KMS key"
  value       = aws_kms_key.general.key_id
}

output "general_key_arn" {
  description = "ARN of the general-purpose KMS key"
  value       = aws_kms_key.general.arn
}

output "general_key_alias" {
  description = "Alias of the general-purpose KMS key"
  value       = aws_kms_alias.general.name
}

output "s3_key_id" {
  description = "ID of the S3 encryption KMS key"
  value       = aws_kms_key.s3.key_id
}

output "s3_key_arn" {
  description = "ARN of the S3 encryption KMS key"
  value       = aws_kms_key.s3.arn
}

output "s3_key_alias" {
  description = "Alias of the S3 encryption KMS key"
  value       = aws_kms_alias.s3.name
}

output "rds_key_id" {
  description = "ID of the RDS encryption KMS key"
  value       = aws_kms_key.rds.key_id
}

output "rds_key_arn" {
  description = "ARN of the RDS encryption KMS key"
  value       = aws_kms_key.rds.arn
}

output "rds_key_alias" {
  description = "Alias of the RDS encryption KMS key"
  value       = aws_kms_alias.rds.name
}

output "ebs_key_id" {
  description = "ID of the EBS encryption KMS key"
  value       = aws_kms_key.ebs.key_id
}

output "ebs_key_arn" {
  description = "ARN of the EBS encryption KMS key"
  value       = aws_kms_key.ebs.arn
}

output "ebs_key_alias" {
  description = "Alias of the EBS encryption KMS key"
  value       = aws_kms_alias.ebs.name
}
