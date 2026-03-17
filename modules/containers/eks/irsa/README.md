# EKS IRSA Module

Terraform module to create an IAM Role for Service Accounts (IRSA) in EKS, with OIDC provider integration, namespace/service account conditions, and policy attachments.

## Features

- IAM role with OIDC-based trust policy
- Namespace and service account name conditions
- Managed policy attachment
- Inline policy support
- Configurable session duration

## Usage

```hcl
module "irsa" {
  source = "../../modules/containers/eks/irsa"

  project     = "myapp"
  environment = "prod"

  role_name_suffix     = "ebs-csi-driver"
  oidc_provider_arn    = module.eks.oidc_provider_arn
  oidc_provider_url    = module.eks.oidc_provider_url
  namespace            = "kube-system"
  service_account_name = "ebs-csi-controller-sa"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  ]

  team = "platform"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| aws | ~> 5.0 |

## Outputs

| Name | Description |
|------|-------------|
| role_arn | IAM role ARN |
| role_name | IAM role name |
