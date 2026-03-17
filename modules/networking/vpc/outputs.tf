output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "vpc_arn" {
  description = "The ARN of the VPC."
  value       = aws_vpc.this.arn
}

output "public_subnet_ids" {
  description = "List of public subnet IDs."
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidr_blocks" {
  description = "List of public subnet CIDR blocks."
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_ids" {
  description = "List of private subnet IDs."
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidr_blocks" {
  description = "List of private subnet CIDR blocks."
  value       = aws_subnet.private[*].cidr_block
}

output "database_subnet_ids" {
  description = "List of database subnet IDs."
  value       = aws_subnet.database[*].id
}

output "database_subnet_cidr_blocks" {
  description = "List of database subnet CIDR blocks."
  value       = aws_subnet.database[*].cidr_block
}

output "database_subnet_group_name" {
  description = "Name of the database subnet group."
  value       = try(aws_db_subnet_group.this[0].name, null)
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway."
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs."
  value       = aws_nat_gateway.this[*].id
}

output "nat_gateway_public_ips" {
  description = "List of public Elastic IPs created for NAT Gateways."
  value       = aws_eip.nat[*].public_ip
}

output "public_route_table_id" {
  description = "The ID of the public route table."
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of private route table IDs."
  value       = aws_route_table.private[*].id
}

output "database_route_table_ids" {
  description = "List of database route table IDs."
  value       = aws_route_table.database[*].id
}

output "flow_log_id" {
  description = "The ID of the VPC Flow Log."
  value       = try(aws_flow_log.this[0].id, null)
}

output "flow_log_cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group for VPC Flow Logs."
  value       = try(aws_cloudwatch_log_group.flow_log[0].arn, null)
}

output "default_security_group_id" {
  description = "The ID of the default security group (restricted)."
  value       = aws_default_security_group.this.id
}

output "vpn_gateway_id" {
  description = "The ID of the VPN Gateway."
  value       = try(aws_vpn_gateway.this[0].id, null)
}

output "availability_zones" {
  description = "List of availability zones used."
  value       = var.availability_zones
}

output "name_prefix" {
  description = "The name prefix used for all resources."
  value       = local.name_prefix
}
