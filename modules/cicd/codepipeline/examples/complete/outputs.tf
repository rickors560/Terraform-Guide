output "pipeline_arn" {
  description = "ARN of the CodePipeline."
  value       = module.pipeline.pipeline_arn
}

output "pipeline_name" {
  description = "Name of the CodePipeline."
  value       = module.pipeline.pipeline_name
}

output "artifact_bucket_id" {
  description = "Artifact bucket ID."
  value       = module.pipeline.artifact_bucket_id
}
