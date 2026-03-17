# EKS Node Group Module

Terraform module to create an EKS managed node group with IAM role, configurable instance types, scaling, labels, taints, and remote access.

## Features

- Managed node group with IAM role and required policies
- Configurable instance types, AMI type, capacity type (ON_DEMAND/SPOT)
- Scaling configuration (min, max, desired)
- Disk size configuration
- Kubernetes labels and taints
- Update configuration (max unavailable)
- Remote access (SSH key, security group)
- SSM agent policy for management

## Usage

```hcl
module "node_group" {
  source = "../../modules/containers/eks/node-group"

  project     = "myapp"
  environment = "prod"

  cluster_name           = module.eks.cluster_name
  node_group_name_suffix = "general"
  subnet_ids             = var.private_subnet_ids

  instance_types = ["t3.large"]
  capacity_type  = "ON_DEMAND"
  min_size       = 2
  max_size        = 10
  desired_size    = 3
  disk_size       = 50

  labels = {
    role = "general"
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
| node_group_id | Node group ID |
| node_group_arn | Node group ARN |
| node_role_arn | Node IAM role ARN |
