output "db_instance_endpoint" {
  description = "RDS endpoint"
  value       = module.rds_postgres.db_instance_endpoint
}

output "db_name" {
  description = "Database name"
  value       = module.rds_postgres.db_name
}
