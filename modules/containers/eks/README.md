# EKS Modules

A collection of Terraform modules for deploying and managing Amazon Elastic Kubernetes Service (EKS) clusters on AWS. These modules are designed to be composed together, with outputs from one feeding as inputs to the next.

## Sub-Modules

| Module | Description |
|--------|-------------|
| [cluster](./cluster/) | EKS control plane with IAM role, endpoint access control, KMS encryption, CloudWatch logging, and OIDC provider for IRSA |
| [node-group](./node-group/) | EKS managed node group with configurable instance types, scaling, labels, taints, and remote access |
| [addons](./addons/) | EKS cluster add-ons (vpc-cni, coredns, kube-proxy, ebs-csi-driver) with IRSA support |
| [irsa](./irsa/) | IAM Roles for Service Accounts with OIDC-based trust policies and policy attachments |

## Deployment Order

The modules must be deployed in a specific order due to resource dependencies:

```
1. cluster      -- EKS control plane, OIDC provider
       |
       v
2. node-group   -- Worker nodes (needs cluster_name)
       |
       v
3. addons       -- Cluster add-ons (needs cluster_name, optional IRSA role ARNs)
       |
       v
4. irsa         -- IAM roles for service accounts (needs OIDC provider ARN/URL)
```

Note: In practice, `irsa` roles that add-ons depend on (such as vpc-cni or ebs-csi-driver) should be created before the `addons` module. The order above represents the logical dependency flow; adjust as needed when add-ons require IRSA roles.

## Architecture and Data Flow

```
+---------------------+
|    cluster module    |
|---------------------|
| Outputs:            |
|  cluster_name    ----+-----------+-----------+
|  cluster_endpoint   |           |           |
|  oidc_provider_arn --+-----+    |           |
|  oidc_provider_url --+---+ |    |           |
+---------------------+   | |    |           |
                           | |    |           |
                 +---------+ |    |           |
                 |           |    |           |
                 v           v    v           v
          +-----------+  +-----------+  +-----------+
          |   irsa    |  | node-group|  |  addons   |
          |-----------|  |-----------|  |-----------|
          | Inputs:   |  | Inputs:   |  | Inputs:   |
          | oidc_arn  |  | cluster   |  | cluster   |
          | oidc_url  |  |   _name   |  |   _name   |
          | namespace |  | subnet_ids|  | irsa      |
          | sa_name   |  |           |  |  role_arns|
          +-----------+  +-----------+  +-----------+
          | Outputs:  |                       ^
          | role_arn ----> (feeds into addons)-+
          +-----------+
```

Key connections:
- **cluster -> node-group**: `cluster_name` output feeds into the node group's `cluster_name` input.
- **cluster -> irsa**: `oidc_provider_arn` and `oidc_provider_url` outputs feed into IRSA's trust policy configuration.
- **cluster -> addons**: `cluster_name` output feeds into the addons module.
- **irsa -> addons**: `role_arn` output from IRSA modules feeds into add-on `service_account_role_arn` inputs.

## Complete Usage Example

The following example composes all four modules to deploy a production EKS cluster with managed node groups, IRSA roles, and cluster add-ons.

```hcl
# --------------------
# 1. EKS Cluster
# --------------------
module "eks_cluster" {
  source = "../../modules/containers/eks/cluster"

  project     = "myapp"
  environment = "prod"

  kubernetes_version      = "1.29"
  subnet_ids              = module.vpc.private_subnet_ids
  endpoint_public_access  = true
  endpoint_private_access = true

  enable_oidc_provider = true

  team        = "platform"
  cost_center = "CC-1234"
}

# --------------------
# 2. Node Group
# --------------------
module "node_group_general" {
  source = "../../modules/containers/eks/node-group"

  project     = "myapp"
  environment = "prod"

  cluster_name           = module.eks_cluster.cluster_name
  node_group_name_suffix = "general"
  subnet_ids             = module.vpc.private_subnet_ids

  instance_types = ["t3.large"]
  capacity_type  = "ON_DEMAND"
  min_size       = 2
  max_size       = 10
  desired_size   = 3
  disk_size      = 50

  labels = {
    role = "general"
  }

  team        = "platform"
  cost_center = "CC-1234"
}

# --------------------
# 3. IRSA Roles
# --------------------
module "vpc_cni_irsa" {
  source = "../../modules/containers/eks/irsa"

  project     = "myapp"
  environment = "prod"

  role_name_suffix     = "vpc-cni"
  oidc_provider_arn    = module.eks_cluster.oidc_provider_arn
  oidc_provider_url    = module.eks_cluster.oidc_provider_url
  namespace            = "kube-system"
  service_account_name = "aws-node"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ]

  team = "platform"
}

module "ebs_csi_irsa" {
  source = "../../modules/containers/eks/irsa"

  project     = "myapp"
  environment = "prod"

  role_name_suffix     = "ebs-csi-driver"
  oidc_provider_arn    = module.eks_cluster.oidc_provider_arn
  oidc_provider_url    = module.eks_cluster.oidc_provider_url
  namespace            = "kube-system"
  service_account_name = "ebs-csi-controller-sa"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  ]

  team = "platform"
}

# --------------------
# 4. Add-ons
# --------------------
module "eks_addons" {
  source = "../../modules/containers/eks/addons"

  project      = "myapp"
  environment  = "prod"
  cluster_name = module.eks_cluster.cluster_name

  addons = {
    vpc-cni = {
      service_account_role_arn = module.vpc_cni_irsa.role_arn
    }
    coredns    = {}
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
| tls | ~> 4.0 |
