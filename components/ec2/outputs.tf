###############################################################################
# EC2 Component — Outputs
###############################################################################

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.main.arn
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.main.private_ip
}

output "public_ip" {
  description = "Public IP (Elastic IP if assigned, otherwise instance public IP)"
  value       = var.assign_elastic_ip ? aws_eip.instance[0].public_ip : aws_instance.main.public_ip
}

output "private_dns" {
  description = "Private DNS name of the instance"
  value       = aws_instance.main.private_dns
}

output "security_group_id" {
  description = "ID of the instance security group"
  value       = aws_security_group.instance.id
}

output "iam_role_arn" {
  description = "ARN of the instance IAM role"
  value       = aws_iam_role.instance.arn
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.instance.name
}

output "availability_zone" {
  description = "Availability zone of the instance"
  value       = aws_instance.main.availability_zone
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = aws_instance.main.ami
}

output "data_volume_id" {
  description = "ID of the additional data EBS volume (if created)"
  value       = var.data_volume_size > 0 ? aws_ebs_volume.data[0].id : null
}
