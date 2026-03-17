# Kubernetes Manifests

Kubernetes manifests and Helm chart for deploying the MyApp full-stack application (Spring Boot backend + React frontend) to an EKS cluster. Supports three environments (dev, staging, prod) using both Kustomize overlays and a Helm chart.

## Directory Structure

```
k8s/
├── base/                                    # Kustomize base manifests
│   ├── kustomization.yaml                   # Base kustomization (namespace, labels, resource list)
│   ├── namespace.yaml                       # Namespace definition with Pod Security Standards
│   ├── ingress.yaml                         # ALB Ingress (internet-facing, SSL redirect)
│   ├── network-policies.yaml                # Network policies (default-deny + allow rules)
│   ├── backend/
│   │   ├── deployment.yaml                  # Backend Deployment (probes, security context, topology)
│   │   ├── service.yaml                     # ClusterIP Service (ports 8080, 8081)
│   │   ├── hpa.yaml                         # HorizontalPodAutoscaler (CPU + memory)
│   │   ├── pdb.yaml                         # PodDisruptionBudget (minAvailable: 1)
│   │   ├── configmap.yaml                   # Application configuration (Spring profiles, logging)
│   │   └── serviceaccount.yaml              # ServiceAccount with IRSA annotation
│   └── frontend/
│       ├── deployment.yaml                  # Frontend Deployment (nginx, probes, security context)
│       ├── service.yaml                     # ClusterIP Service (port 80)
│       └── hpa.yaml                         # HorizontalPodAutoscaler (CPU)
├── overlays/                                # Environment-specific Kustomize patches
│   ├── dev/
│   │   ├── kustomization.yaml               # Dev overlay (namePrefix: dev-, configMapGenerator)
│   │   └── patches/
│   │       ├── deployment-backend.yaml       # 1 replica, reduced resources, dev profile
│   │       ├── deployment-frontend.yaml      # 1 replica, reduced resources
│   │       ├── hpa-backend.yaml              # HPA min=1, max=3
│   │       └── ingress.yaml                  # Host: dev.myapp.example.com
│   ├── staging/
│   │   ├── kustomization.yaml               # Staging overlay (namePrefix: staging-)
│   │   └── patches/
│   │       ├── deployment-backend.yaml       # 2 replicas, staging profile
│   │       ├── deployment-frontend.yaml      # 2 replicas, base resources
│   │       └── ingress.yaml                  # Host: staging.myapp.example.com
│   └── prod/
│       ├── kustomization.yaml               # Prod overlay (namePrefix: prod-)
│       └── patches/
│           ├── deployment-backend.yaml       # 3 replicas, anti-affinity, JVM tuning
│           ├── deployment-frontend.yaml      # 3 replicas, anti-affinity
│           ├── hpa-backend.yaml              # HPA min=3, max=20, conservative scale-down
│           └── ingress.yaml                  # WAFv2, Shield, access logging
├── helm/
│   └── app-chart/                           # Helm chart (alternative to Kustomize)
│       ├── Chart.yaml                       # Chart metadata (v1.0.0)
│       ├── values.yaml                      # Default values
│       ├── values-dev.yaml                  # Dev overrides
│       ├── values-staging.yaml              # Staging overrides
│       ├── values-prod.yaml                 # Prod overrides
│       └── templates/
│           ├── _helpers.tpl                 # Template helper functions
│           ├── deployment-backend.yaml      # Backend deployment template
│           ├── deployment-frontend.yaml     # Frontend deployment template
│           ├── service-backend.yaml         # Backend service template
│           ├── service-frontend.yaml        # Frontend service template
│           ├── configmap.yaml               # ConfigMap template
│           ├── secret.yaml                  # Secret template (optional)
│           ├── ingress.yaml                 # Ingress template
│           ├── hpa.yaml                     # HPA template
│           ├── serviceaccount.yaml          # ServiceAccount template
│           └── NOTES.txt                    # Post-install help text
└── README.md                                # This file
```

## Kustomize Base/Overlay Pattern

The manifests follow the Kustomize base/overlay pattern:

- **Base** (`k8s/base/`) contains the complete set of resource definitions with sensible defaults (2 replicas, moderate resource requests, all probes configured). The base is never applied directly to a cluster.
- **Overlays** (`k8s/overlays/<env>/`) reference the base and apply strategic merge patches to customize replica counts, resource limits, hostnames, HPA settings, Spring profiles, and security features per environment.

This pattern keeps environment-specific differences minimal and auditable while sharing a single source of truth for the application structure.

## What Each Manifest Does

| Manifest | Purpose |
|---|---|
| `namespace.yaml` | Creates the `myapp` namespace with `restricted` Pod Security Standards |
| `backend/deployment.yaml` | Backend Deployment with startup/readiness/liveness probes, non-root security context, topology spread constraints, Prometheus annotations, and graceful shutdown |
| `backend/service.yaml` | ClusterIP Service exposing port 8080 (HTTP) and 8081 (management/metrics) |
| `backend/hpa.yaml` | Autoscaler targeting 70% CPU and 80% memory utilization (2-10 replicas base) |
| `backend/pdb.yaml` | PodDisruptionBudget requiring at least 1 pod available during disruptions |
| `backend/configmap.yaml` | Spring Boot configuration: profiles, server settings, logging, CORS, pagination |
| `backend/serviceaccount.yaml` | ServiceAccount annotated for IAM Roles for Service Accounts (IRSA) |
| `frontend/deployment.yaml` | Frontend Deployment running nginx on port 8080, read-only filesystem, non-root user (UID 101) |
| `frontend/service.yaml` | ClusterIP Service exposing port 80 mapped to container port 8080 |
| `frontend/hpa.yaml` | Autoscaler targeting 70% CPU utilization (2-6 replicas base) |
| `ingress.yaml` | ALB Ingress: internet-facing, HTTPS redirect, `/api` routes to backend, `/` routes to frontend |
| `network-policies.yaml` | Default-deny all traffic, then allow: DNS egress for all pods, ALB ingress to frontend, frontend/ALB ingress to backend, monitoring namespace to backend metrics port, backend egress to HTTPS/PostgreSQL/Redis |

## Deploying to Each Environment

```bash
# Preview the rendered manifests
kubectl kustomize k8s/overlays/dev
kubectl kustomize k8s/overlays/staging
kubectl kustomize k8s/overlays/prod

# Apply to the cluster
kubectl apply -k k8s/overlays/dev
kubectl apply -k k8s/overlays/staging
kubectl apply -k k8s/overlays/prod

# Verify the deployment
kubectl get all -n myapp
kubectl get ingress -n myapp
```

## Helm Chart vs Kustomize

Both the Kustomize overlays and the Helm chart deploy the same application. Choose based on your workflow:

- **Kustomize**: Native kubectl integration, no extra tooling, patch-based customization. Best when you want to keep raw YAML and manage differences as patches.
- **Helm**: Templated values, release management (install/upgrade/rollback history), dependency management. Best when you need programmatic value injection or release lifecycle tracking.

See `k8s/helm/README.md` for Helm-specific usage.

## Prerequisites

- An EKS cluster provisioned by the Terraform modules in this repository
- `kubectl` configured to access the cluster (`./scripts/eks-kubeconfig.sh --cluster myapp-cluster`)
- The `myapp` namespace exists (created automatically by `namespace.yaml`)
- AWS Load Balancer Controller installed in the cluster (for ALB Ingress)
- An ACM certificate ARN configured in `ingress.yaml` for HTTPS
- Container images pushed to ECR (see `application/` directory)
