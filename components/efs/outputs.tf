# -----------------------------------------------------------------------------
# EFS Component - Outputs
# -----------------------------------------------------------------------------

output "file_system_id" {
  description = "ID of the EFS file system"
  value       = aws_efs_file_system.main.id
}

output "file_system_arn" {
  description = "ARN of the EFS file system"
  value       = aws_efs_file_system.main.arn
}

output "file_system_dns_name" {
  description = "DNS name of the EFS file system"
  value       = aws_efs_file_system.main.dns_name
}

output "security_group_id" {
  description = "ID of the EFS security group"
  value       = aws_security_group.efs.id
}

output "mount_target_ids" {
  description = "Map of subnet IDs to mount target IDs"
  value       = { for k, v in aws_efs_mount_target.main : k => v.id }
}

output "mount_target_ips" {
  description = "Map of subnet IDs to mount target IP addresses"
  value       = { for k, v in aws_efs_mount_target.main : k => v.ip_address }
}

output "app_access_point_id" {
  description = "ID of the application access point"
  value       = aws_efs_access_point.app.id
}

output "app_access_point_arn" {
  description = "ARN of the application access point"
  value       = aws_efs_access_point.app.arn
}

output "logs_access_point_id" {
  description = "ID of the logs access point"
  value       = aws_efs_access_point.logs.id
}

output "shared_access_point_id" {
  description = "ID of the shared access point"
  value       = aws_efs_access_point.shared.id
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for EFS encryption"
  value       = aws_kms_key.efs.arn
}
