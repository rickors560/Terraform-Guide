# -----------------------------------------------------------------------------
# Transit Gateway Component - Outputs
# -----------------------------------------------------------------------------

output "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  value       = aws_ec2_transit_gateway.main.id
}

output "transit_gateway_arn" {
  description = "ARN of the Transit Gateway"
  value       = aws_ec2_transit_gateway.main.arn
}

output "transit_gateway_asn" {
  description = "ASN of the Transit Gateway"
  value       = aws_ec2_transit_gateway.main.amazon_side_asn
}

output "shared_services_route_table_id" {
  description = "ID of the shared services route table"
  value       = aws_ec2_transit_gateway_route_table.shared_services.id
}

output "isolated_route_table_id" {
  description = "ID of the isolated route table"
  value       = aws_ec2_transit_gateway_route_table.isolated.id
}

output "egress_route_table_id" {
  description = "ID of the egress route table"
  value       = aws_ec2_transit_gateway_route_table.egress.id
}

output "vpc_attachment_ids" {
  description = "Map of VPC attachment names to their IDs"
  value       = { for k, v in aws_ec2_transit_gateway_vpc_attachment.vpcs : k => v.id }
}

output "ram_resource_share_arn" {
  description = "ARN of the RAM resource share (empty if not sharing)"
  value       = length(aws_ram_resource_share.tgw) > 0 ? aws_ram_resource_share.tgw[0].arn : ""
}
