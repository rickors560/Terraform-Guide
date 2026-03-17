# EKS Add-ons Module

Terraform module to manage EKS cluster add-ons with configurable versions, conflict resolution policies, and IRSA support.

## Features

- Configurable list of add-ons with versions
- Resolve conflicts policy (create and update)
- Service account role ARN for IRSA
- Custom configuration values

## Usage

```hcl
module "eks_addons" {
  source = "../../modules/containers/eks/addons"

  project      = "myapp"
  environment  = "prod"
  cluster_name = module.eks.cluster_name

  addons = {
    vpc-cni = {
      service_account_role_arn = module.vpc_cni_irsa.role_arn
    }
    coredns = {}
    kube-proxy = {}
    aws-ebs-csi-driver = {
      service_account_role_arn = module.ebs_csi_irsa.role_arn
    }
  }

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
| addon_ids | Map of addon name to ID |
| addon_arns | Map of addon name to ARN |
| addon_versions | Map of addon name to version |
