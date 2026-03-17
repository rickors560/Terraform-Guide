output "file_system_id" {
  description = "EFS file system ID"
  value       = module.efs.file_system_id
}

output "file_system_dns_name" {
  description = "EFS DNS name"
  value       = module.efs.file_system_dns_name
}

output "access_point_ids" {
  description = "Access point IDs"
  value       = module.efs.access_point_ids
}
