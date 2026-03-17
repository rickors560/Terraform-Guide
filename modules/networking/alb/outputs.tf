output "alb_id" {
  description = "The ID of the ALB."
  value       = aws_lb.this.id
}

output "alb_arn" {
  description = "The ARN of the ALB."
  value       = aws_lb.this.arn
}

output "alb_arn_suffix" {
  description = "The ARN suffix of the ALB for use with CloudWatch Metrics."
  value       = aws_lb.this.arn_suffix
}

output "alb_dns_name" {
  description = "The DNS name of the ALB."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the ALB (for Route53 alias records)."
  value       = aws_lb.this.zone_id
}

output "http_listener_arn" {
  description = "The ARN of the HTTP listener."
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "The ARN of the HTTPS listener."
  value       = try(aws_lb_listener.https[0].arn, null)
}

output "target_group_arn" {
  description = "The ARN of the default target group."
  value       = aws_lb_target_group.this.arn
}

output "target_group_arn_suffix" {
  description = "The ARN suffix of the default target group."
  value       = aws_lb_target_group.this.arn_suffix
}

output "target_group_name" {
  description = "The name of the default target group."
  value       = aws_lb_target_group.this.name
}
