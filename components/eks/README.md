# EKS Component

Production-grade EKS cluster with managed node group, OIDC provider, essential add-ons, secrets encryption, and CloudWatch logging.

## Features

- EKS cluster with configurable Kubernetes version
- OIDC provider for IAM Roles for Service Accounts (IRSA)
- Managed node group with configurable instance types and scaling
- Essential add-ons: VPC CNI, CoreDNS, kube-proxy, EBS CSI driver
- KMS encryption for Kubernetes secrets
- Full control plane logging to CloudWatch
- SSM access to worker nodes

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply

# Configure kubectl
$(terraform output -raw kubeconfig_command)
kubectl get nodes
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `vpc_id` | VPC ID | `string` | — |
| `private_subnet_ids` | Subnet IDs | `list(string)` | — |
| `cluster_version` | K8s version | `string` | `1.31` |
| `node_instance_types` | Instance types | `list(string)` | `["t3.medium"]` |
| `node_desired_size` | Desired nodes | `number` | `2` |
| `node_max_size` | Max nodes | `number` | `5` |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_endpoint` | API server endpoint |
| `cluster_name` | Cluster name |
| `oidc_provider_arn` | OIDC provider ARN |
| `kubeconfig_command` | kubectl config command |
