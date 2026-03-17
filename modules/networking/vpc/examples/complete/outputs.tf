output "vpc_id" {
  description = "The ID of the VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs."
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "List of database subnet IDs."
  value       = module.vpc.database_subnet_ids
}

output "nat_gateway_public_ips" {
  description = "NAT Gateway public IPs."
  value       = module.vpc.nat_gateway_public_ips
}
