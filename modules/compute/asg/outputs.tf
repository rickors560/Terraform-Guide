output "asg_id" {
  description = "ID of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.id
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.arn
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.name
}

output "asg_min_size" {
  description = "Minimum size of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.min_size
}

output "asg_max_size" {
  description = "Maximum size of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.max_size
}

output "asg_desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.desired_capacity
}

output "cpu_target_tracking_policy_arn" {
  description = "ARN of the CPU target tracking scaling policy"
  value       = var.enable_target_tracking_cpu ? aws_autoscaling_policy.cpu_target_tracking[0].arn : null
}

output "alb_request_count_policy_arn" {
  description = "ARN of the ALB request count target tracking scaling policy"
  value       = var.enable_target_tracking_alb_request_count ? aws_autoscaling_policy.alb_request_count_target_tracking[0].arn : null
}
