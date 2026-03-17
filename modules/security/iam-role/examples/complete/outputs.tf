output "ecs_task_role_arn" {
  description = "ECS task role ARN."
  value       = module.ecs_task_role.role_arn
}

output "ec2_instance_role_arn" {
  description = "EC2 instance role ARN."
  value       = module.ec2_instance_role.role_arn
}

output "ec2_instance_profile_arn" {
  description = "EC2 instance profile ARN."
  value       = module.ec2_instance_role.instance_profile_arn
}
