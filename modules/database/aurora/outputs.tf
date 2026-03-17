output "cluster_id" {
  description = "ID of the Aurora cluster"
  value       = aws_rds_cluster.this.id
}

output "cluster_arn" {
  description = "ARN of the Aurora cluster"
  value       = aws_rds_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Writer endpoint of the Aurora cluster"
  value       = aws_rds_cluster.this.endpoint
}

output "cluster_reader_endpoint" {
  description = "Reader endpoint of the Aurora cluster"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "cluster_port" {
  description = "Port of the Aurora cluster"
  value       = aws_rds_cluster.this.port
}

output "cluster_database_name" {
  description = "Name of the default database"
  value       = aws_rds_cluster.this.database_name
}

output "cluster_master_username" {
  description = "Master username"
  value       = aws_rds_cluster.this.master_username
  sensitive   = true
}

output "cluster_resource_id" {
  description = "Resource ID of the Aurora cluster"
  value       = aws_rds_cluster.this.cluster_resource_id
}

output "instance_ids" {
  description = "List of instance IDs"
  value       = aws_rds_cluster_instance.this[*].id
}

output "instance_endpoints" {
  description = "List of instance endpoints"
  value       = aws_rds_cluster_instance.this[*].endpoint
}

output "master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret for the master password"
  value       = var.manage_master_user_password && !var.enable_global_database ? aws_rds_cluster.this.master_user_secret[0].secret_arn : null
}
