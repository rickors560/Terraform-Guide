# 06 - Kubernetes

Running Kubernetes on AWS with Amazon EKS. This section covers provisioning EKS clusters with Terraform, managing Kubernetes manifests, deploying Helm charts, configuring ingress and DNS, autoscaling, observability, and service mesh.

## Prerequisites

- Basic Kubernetes concepts: pods, deployments, services, namespaces, RBAC.
- Completion of [01 - Terraform Basics](../01-terraform-basics/) and [02 - Terraform Intermediate](../02-terraform-intermediate/).
- Familiarity with [04 - AWS Services Guide / containers.md](../04-aws-services-guide/containers.md) is helpful.
- `kubectl` and `helm` CLI tools installed.

## Learning Objectives

After completing this section, you will be able to:

- Provision a production-ready EKS cluster with Terraform
- Configure managed node groups, Fargate profiles, and cluster add-ons
- Deploy Kubernetes manifests alongside Terraform using the Kubernetes provider
- Manage Helm chart releases with the Helm Terraform provider
- Set up ALB Ingress Controller and external-dns for automatic DNS management
- Configure Cluster Autoscaler, HPA, and Karpenter for workload scaling
- Implement observability with Prometheus, Grafana, CloudWatch, and Fluent Bit
- Evaluate and deploy a service mesh (Istio, Linkerd, or App Mesh)

## Documents

| # | File | Description | Est. Reading Time |
|---|------|-------------|-------------------|
| 1 | [eks-overview.md](./eks-overview.md) | EKS architecture, control plane vs. data plane, networking modes (VPC CNI), OIDC integration, and EKS vs. self-managed Kubernetes. | 15 min |
| 2 | [eks-terraform.md](./eks-terraform.md) | Provisioning EKS with Terraform: cluster module, node groups, add-ons (CoreDNS, kube-proxy, VPC CNI, EBS CSI), and IRSA setup. | 20 min |
| 3 | [k8s-manifests-guide.md](./k8s-manifests-guide.md) | Managing Kubernetes resources with the Terraform Kubernetes provider. Deployments, services, config maps, secrets, and when to use Terraform vs. kubectl. | 15 min |
| 4 | [helm-with-terraform.md](./helm-with-terraform.md) | Deploying Helm charts with the Terraform Helm provider. Chart repositories, values overrides, release management, and chart version pinning. | 15 min |
| 5 | [ingress-and-dns.md](./ingress-and-dns.md) | AWS Load Balancer Controller (ALB Ingress), external-dns for automatic Route 53 records, TLS termination with ACM, and ingress class configuration. | 15 min |
| 6 | [autoscaling.md](./autoscaling.md) | Cluster Autoscaler, Horizontal Pod Autoscaler (HPA), Vertical Pod Autoscaler (VPA), Karpenter for node provisioning, and scaling strategies. | 15 min |
| 7 | [observability.md](./observability.md) | Monitoring EKS: Prometheus + Grafana stack, CloudWatch Container Insights, Fluent Bit log forwarding, distributed tracing, and alerting. | 15 min |
| 8 | [service-mesh.md](./service-mesh.md) | Service mesh options on EKS: Istio, Linkerd, and AWS App Mesh. Traffic management, mTLS, observability, and Terraform integration. | 15 min |

**Total estimated reading time: ~125 minutes**

## Suggested Reading Order

1. Start with `eks-overview.md` for the architecture context.
2. Read `eks-terraform.md` to understand how the EKS modules work.
3. Choose your deployment method: `k8s-manifests-guide.md` and/or `helm-with-terraform.md`.
4. Set up ingress: `ingress-and-dns.md`.
5. Add scaling: `autoscaling.md`.
6. Add observability: `observability.md`.
7. Evaluate service mesh: `service-mesh.md` (optional, for complex microservice architectures).

## Hands-On Practice

- **EKS Modules:** The cluster is split across four modules in `modules/containers/eks/`:
  - `modules/containers/eks/cluster/` -- EKS control plane
  - `modules/containers/eks/node-group/` -- Managed node groups
  - `modules/containers/eks/addons/` -- Cluster add-ons
  - `modules/containers/eks/irsa/` -- IAM Roles for Service Accounts
- **EKS Component:** `components/eks/` composes all four EKS modules into a single deployable unit.
- **Supporting Components:** `components/ecr/` for container image storage, `components/alb/` for load balancing, `components/route53/` for DNS.

## What's Next

Continue to [07 - Production Patterns](../07-production-patterns/) for multi-environment strategies, disaster recovery, and cost optimization patterns that apply to EKS and all other infrastructure.
