output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.this.arn
}

output "private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.this.public_ip
}

output "private_dns" {
  description = "Private DNS name of the EC2 instance"
  value       = aws_instance.this.private_dns
}

output "public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.this.public_dns
}

output "primary_network_interface_id" {
  description = "ID of the primary network interface"
  value       = aws_instance.this.primary_network_interface_id
}

output "availability_zone" {
  description = "Availability zone of the EC2 instance"
  value       = aws_instance.this.availability_zone
}

output "eip_public_ip" {
  description = "Elastic IP address associated with the instance"
  value       = var.associate_eip ? aws_eip.this[0].public_ip : null
}

output "eip_allocation_id" {
  description = "Allocation ID of the Elastic IP"
  value       = var.associate_eip ? aws_eip.this[0].id : null
}

output "instance_state" {
  description = "State of the EC2 instance"
  value       = aws_instance.this.instance_state
}
