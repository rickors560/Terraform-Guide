output "volume_id" {
  description = "ID of the EBS volume"
  value       = aws_ebs_volume.this.id
}

output "volume_arn" {
  description = "ARN of the EBS volume"
  value       = aws_ebs_volume.this.arn
}

output "availability_zone" {
  description = "Availability zone of the volume"
  value       = aws_ebs_volume.this.availability_zone
}

output "size" {
  description = "Size of the volume in GiB"
  value       = aws_ebs_volume.this.size
}

output "type" {
  description = "Volume type"
  value       = aws_ebs_volume.this.type
}

output "encrypted" {
  description = "Whether the volume is encrypted"
  value       = aws_ebs_volume.this.encrypted
}
