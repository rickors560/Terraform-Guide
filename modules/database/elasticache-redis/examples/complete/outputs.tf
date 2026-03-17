output "primary_endpoint" {
  description = "Redis primary endpoint"
  value       = module.redis.primary_endpoint_address
}

output "reader_endpoint" {
  description = "Redis reader endpoint"
  value       = module.redis.reader_endpoint_address
}
