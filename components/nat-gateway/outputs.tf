# -----------------------------------------------------------------------------
# NAT Gateway Component - Outputs
# -----------------------------------------------------------------------------

output "nat_gateway_ids" {
  description = "List of public NAT Gateway IDs"
  value       = aws_nat_gateway.public[*].id
}

output "nat_gateway_public_ips" {
  description = "List of public IP addresses of the NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

output "eip_allocation_ids" {
  description = "List of EIP allocation IDs"
  value       = aws_eip.nat[*].allocation_id
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = aws_route_table.private[*].id
}

output "private_nat_gateway_id" {
  description = "ID of the private NAT Gateway (empty if not created)"
  value       = length(aws_nat_gateway.private) > 0 ? aws_nat_gateway.private[0].id : ""
}
