output "instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2_instance.instance_id
}

output "private_ip" {
  description = "Private IP address"
  value       = module.ec2_instance.private_ip
}

output "public_ip" {
  description = "Public IP address"
  value       = module.ec2_instance.public_ip
}

output "eip_public_ip" {
  description = "Elastic IP address"
  value       = module.ec2_instance.eip_public_ip
}
