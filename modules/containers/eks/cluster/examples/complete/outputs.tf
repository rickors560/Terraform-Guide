output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks_cluster.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks_cluster.cluster_endpoint
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN"
  value       = module.eks_cluster.oidc_provider_arn
}
