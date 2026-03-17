###############################################################################
# ElastiCache Component — Outputs
###############################################################################

output "replication_group_id" {
  description = "ID of the Redis replication group"
  value       = aws_elasticache_replication_group.main.id
}

output "replication_group_arn" {
  description = "ARN of the Redis replication group"
  value       = aws_elasticache_replication_group.main.arn
}

output "primary_endpoint" {
  description = "Primary endpoint address for writes"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "reader_endpoint" {
  description = "Reader endpoint address for reads"
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
}

output "port" {
  description = "Redis port"
  value       = var.port
}

output "security_group_id" {
  description = "ID of the Redis security group"
  value       = aws_security_group.redis.id
}

output "auth_secret_arn" {
  description = "ARN of the Secrets Manager secret with auth token"
  value       = aws_secretsmanager_secret.redis_auth.arn
}

output "subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  value       = aws_elasticache_subnet_group.main.name
}
