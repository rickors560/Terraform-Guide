# -----------------------------------------------------------------------------
# EBS Component - Outputs
# -----------------------------------------------------------------------------

output "app_data_volume_id" {
  description = "ID of the application data EBS volume"
  value       = aws_ebs_volume.app_data.id
}

output "app_data_volume_arn" {
  description = "ARN of the application data EBS volume"
  value       = aws_ebs_volume.app_data.arn
}

output "logs_volume_id" {
  description = "ID of the logs EBS volume"
  value       = aws_ebs_volume.logs.id
}

output "logs_volume_arn" {
  description = "ARN of the logs EBS volume"
  value       = aws_ebs_volume.logs.arn
}

output "initial_snapshot_id" {
  description = "ID of the initial app data snapshot"
  value       = aws_ebs_snapshot.app_data_initial.id
}

output "dlm_lifecycle_policy_id" {
  description = "ID of the DLM lifecycle policy"
  value       = aws_dlm_lifecycle_policy.ebs_snapshots.id
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for EBS encryption"
  value       = aws_kms_key.ebs.arn
}

output "kms_key_alias" {
  description = "Alias of the KMS key"
  value       = aws_kms_alias.ebs.name
}
