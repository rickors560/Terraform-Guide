# -----------------------------------------------------------------------------
# Security Groups Component - Outputs
# -----------------------------------------------------------------------------

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "alb_security_group_arn" {
  description = "ARN of the ALB security group"
  value       = aws_security_group.alb.arn
}

output "app_security_group_id" {
  description = "ID of the application tier security group"
  value       = aws_security_group.app.id
}

output "app_security_group_arn" {
  description = "ARN of the application tier security group"
  value       = aws_security_group.app.arn
}

output "db_security_group_id" {
  description = "ID of the database tier security group"
  value       = aws_security_group.db.id
}

output "db_security_group_arn" {
  description = "ARN of the database tier security group"
  value       = aws_security_group.db.arn
}

output "cache_security_group_id" {
  description = "ID of the cache tier security group"
  value       = aws_security_group.cache.id
}

output "cache_security_group_arn" {
  description = "ARN of the cache tier security group"
  value       = aws_security_group.cache.arn
}

output "bastion_security_group_id" {
  description = "ID of the bastion security group (empty if not created)"
  value       = length(aws_security_group.bastion) > 0 ? aws_security_group.bastion[0].id : ""
}

output "all_security_group_ids" {
  description = "Map of all security group IDs by tier name"
  value = {
    alb     = aws_security_group.alb.id
    app     = aws_security_group.app.id
    db      = aws_security_group.db.id
    cache   = aws_security_group.cache.id
    bastion = length(aws_security_group.bastion) > 0 ? aws_security_group.bastion[0].id : ""
  }
}
