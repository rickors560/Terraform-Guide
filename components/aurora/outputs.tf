###############################################################################
# Aurora Component — Outputs
###############################################################################

output "cluster_id" {
  description = "Aurora cluster identifier"
  value       = aws_rds_cluster.main.id
}

output "cluster_arn" {
  description = "ARN of the Aurora cluster"
  value       = aws_rds_cluster.main.arn
}

output "cluster_endpoint" {
  description = "Writer endpoint for the cluster"
  value       = aws_rds_cluster.main.endpoint
}

output "reader_endpoint" {
  description = "Reader endpoint for the cluster"
  value       = aws_rds_cluster.main.reader_endpoint
}

output "cluster_port" {
  description = "Database port"
  value       = aws_rds_cluster.main.port
}

output "database_name" {
  description = "Name of the default database"
  value       = aws_rds_cluster.main.database_name
}

output "instance_ids" {
  description = "List of Aurora instance identifiers"
  value       = aws_rds_cluster_instance.main[*].identifier
}

output "instance_endpoints" {
  description = "List of Aurora instance endpoints"
  value       = aws_rds_cluster_instance.main[*].endpoint
}

output "security_group_id" {
  description = "ID of the Aurora security group"
  value       = aws_security_group.aurora.id
}

output "credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.aurora_credentials.arn
}

output "subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.aurora.name
}
