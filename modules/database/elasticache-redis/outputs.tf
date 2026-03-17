output "replication_group_id" {
  description = "ID of the ElastiCache replication group"
  value       = aws_elasticache_replication_group.this.id
}

output "replication_group_arn" {
  description = "ARN of the ElastiCache replication group"
  value       = aws_elasticache_replication_group.this.arn
}

output "primary_endpoint_address" {
  description = "Primary endpoint address"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Reader endpoint address"
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "configuration_endpoint_address" {
  description = "Configuration endpoint address (cluster mode only)"
  value       = var.enable_cluster_mode ? aws_elasticache_replication_group.this.configuration_endpoint_address : null
}

output "port" {
  description = "Redis port"
  value       = aws_elasticache_replication_group.this.port
}

output "member_clusters" {
  description = "Member clusters of the replication group"
  value       = aws_elasticache_replication_group.this.member_clusters
}
