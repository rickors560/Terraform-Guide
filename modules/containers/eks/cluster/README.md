# EKS Cluster Module

Terraform module to create an AWS EKS cluster with IAM role, security group, endpoint access control, KMS encryption, cluster add-ons, CloudWatch logging, and OIDC provider for IRSA.

## Features

- EKS cluster with configurable Kubernetes version
- Cluster IAM role with required policies
- Public/private endpoint access toggles
- KMS encryption for Kubernetes secrets
- Cluster add-ons (vpc-cni, coredns, kube-proxy, ebs-csi-driver)
- CloudWatch logging (api, audit, authenticator, controllerManager, scheduler)
- OIDC provider for IAM Roles for Service Accounts (IRSA)

## Usage

```hcl
module "eks_cluster" {
  source = "../../modules/containers/eks/cluster"

  project     = "myapp"
  environment = "prod"

  kubernetes_version      = "1.29"
  subnet_ids              = ["subnet-xxx", "subnet-yyy"]
  endpoint_public_access  = true
  endpoint_private_access = true

  enable_oidc_provider = true

  team        = "platform"
  cost_center = "CC-1234"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| aws | ~> 5.0 |
| tls | ~> 4.0 |

## Outputs

| Name | Description |
|------|-------------|
| cluster_name | EKS cluster name |
| cluster_endpoint | API server endpoint |
| cluster_arn | EKS cluster ARN |
| oidc_provider_arn | OIDC provider ARN |
| oidc_provider_url | OIDC provider URL |
