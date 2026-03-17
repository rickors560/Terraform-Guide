###############################################################################
# NLB Component — Outputs
###############################################################################

output "nlb_id" {
  description = "NLB ID"
  value       = aws_lb.main.id
}

output "nlb_arn" {
  description = "NLB ARN"
  value       = aws_lb.main.arn
}

output "nlb_arn_suffix" {
  description = "NLB ARN suffix"
  value       = aws_lb.main.arn_suffix
}

output "nlb_dns_name" {
  description = "NLB DNS name"
  value       = aws_lb.main.dns_name
}

output "nlb_zone_id" {
  description = "NLB hosted zone ID (for Route53 alias records)"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "Target group ARN"
  value       = aws_lb_target_group.tcp.arn
}

output "target_group_name" {
  description = "Target group name"
  value       = aws_lb_target_group.tcp.name
}

output "tcp_listener_arn" {
  description = "TCP listener ARN"
  value       = aws_lb_listener.tcp.arn
}

output "tls_listener_arn" {
  description = "TLS listener ARN (if created)"
  value       = var.acm_certificate_arn != "" ? aws_lb_listener.tls[0].arn : null
}
