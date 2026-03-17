# -----------------------------------------------------------------------------
# VPC Peering Component - Outputs
# -----------------------------------------------------------------------------

output "peering_connection_id" {
  description = "ID of the VPC peering connection"
  value       = aws_vpc_peering_connection.main.id
}

output "peering_connection_status" {
  description = "Status of the VPC peering connection"
  value       = aws_vpc_peering_connection.main.accept_status
}

output "requester_vpc_id" {
  description = "VPC ID of the requester"
  value       = var.requester_vpc_id
}

output "accepter_vpc_id" {
  description = "VPC ID of the accepter"
  value       = var.accepter_vpc_id
}
