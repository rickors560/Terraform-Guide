output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = module.ecs_fargate.cluster_arn
}

output "service_name" {
  description = "ECS service name"
  value       = module.ecs_fargate.service_name
}

output "task_definition_arn" {
  description = "Task definition ARN"
  value       = module.ecs_fargate.task_definition_arn
}
