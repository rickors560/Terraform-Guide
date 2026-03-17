output "file_system_id" {
  description = "ID of the EFS file system"
  value       = aws_efs_file_system.this.id
}

output "file_system_arn" {
  description = "ARN of the EFS file system"
  value       = aws_efs_file_system.this.arn
}

output "file_system_dns_name" {
  description = "DNS name of the EFS file system"
  value       = aws_efs_file_system.this.dns_name
}

output "mount_target_ids" {
  description = "List of mount target IDs"
  value       = aws_efs_mount_target.this[*].id
}

output "mount_target_dns_names" {
  description = "List of mount target DNS names"
  value       = aws_efs_mount_target.this[*].dns_name
}

output "mount_target_network_interface_ids" {
  description = "List of mount target network interface IDs"
  value       = aws_efs_mount_target.this[*].network_interface_id
}

output "access_point_ids" {
  description = "List of access point IDs"
  value       = aws_efs_access_point.this[*].id
}

output "access_point_arns" {
  description = "List of access point ARNs"
  value       = aws_efs_access_point.this[*].arn
}
