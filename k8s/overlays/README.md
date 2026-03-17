# Kustomize Overlays

Environment-specific Kustomize patches that customize the base manifests in `k8s/base/` for each deployment target. Each overlay adjusts replica counts, resource allocations, Spring Boot profiles, ingress hostnames, HPA behavior, and security features.

## Directory Structure

```
overlays/
├── dev/
│   ├── kustomization.yaml
│   └── patches/
│       ├── deployment-backend.yaml
│       ├── deployment-frontend.yaml
│       ├── hpa-backend.yaml
│       └── ingress.yaml
├── staging/
│   ├── kustomization.yaml
│   └── patches/
│       ├── deployment-backend.yaml
│       ├── deployment-frontend.yaml
│       └── ingress.yaml
└── prod/
    ├── kustomization.yaml
    └── patches/
        ├── deployment-backend.yaml
        ├── deployment-frontend.yaml
        ├── hpa-backend.yaml
        └── ingress.yaml
```

## Environment Comparison

| Parameter | Dev | Staging | Prod |
|---|---|---|---|
| **Name prefix** | `dev-` | `staging-` | `prod-` |
| **Environment label** | `dev` | `staging` | `production` |
| **Backend replicas** | 1 | 2 | 3 |
| **Frontend replicas** | 1 | 2 | 3 |
| **Backend CPU request/limit** | 250m / 500m | 500m / 1000m | 1000m / 2000m |
| **Backend memory request/limit** | 256Mi / 512Mi | 512Mi / 1Gi | 1Gi / 2Gi |
| **Frontend CPU request/limit** | 50m / 250m | 100m / 500m | 200m / 1000m |
| **Frontend memory request/limit** | 64Mi / 128Mi | 128Mi / 256Mi | 256Mi / 512Mi |
| **Spring profile** | `dev` | `staging` | `prod` |
| **Log level** | `DEBUG` | `INFO` | `WARN` |
| **CORS origins** | `localhost:3000`, `dev.myapp.example.com` | `staging.myapp.example.com` | `myapp.example.com` |
| **Hostname** | `dev.myapp.example.com` | `staging.myapp.example.com` | `myapp.example.com` |
| **HPA backend min/max** | 1 / 3 | 2 / 10 (base) | 3 / 20 |
| **HPA scale-down stabilization** | 300s (base) | 300s (base) | 600s |
| **Pod anti-affinity** | None | None | Required (hostname), preferred (zone) |
| **JVM tuning** | None | None | `-XX:MaxRAMPercentage=75.0 -XX:+UseG1GC -XX:+UseStringDeduplication` |
| **WAFv2 / Shield** | No | No | Yes |
| **ALB access logging** | No | No | Yes (S3 bucket) |

## How to Apply Each Overlay

```bash
# Dev
kubectl kustomize k8s/overlays/dev          # preview
kubectl apply -k k8s/overlays/dev           # apply

# Staging
kubectl kustomize k8s/overlays/staging      # preview
kubectl apply -k k8s/overlays/staging       # apply

# Prod
kubectl kustomize k8s/overlays/prod         # preview
kubectl apply -k k8s/overlays/prod          # apply

# Delete all resources for an environment
kubectl delete -k k8s/overlays/dev
```

## How Patches Work

Each overlay uses **strategic merge patches** -- partial YAML documents that Kustomize merges into the base resources by matching on `apiVersion`, `kind`, and `metadata.name`.

For example, the dev backend deployment patch:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 1
  template:
    spec:
      containers:
        - name: backend
          resources:
            requests:
              cpu: 250m
              memory: 256Mi
```

Kustomize matches this to the base `backend` Deployment and replaces only the fields specified in the patch. All other fields from the base (probes, security context, volumes, etc.) remain unchanged.

Each overlay also uses a `configMapGenerator` with `behavior: merge` to override specific keys in the backend ConfigMap:

```yaml
configMapGenerator:
  - name: backend-config
    behavior: merge
    literals:
      - SPRING_PROFILES_ACTIVE=dev
      - LOGGING_LEVEL_ROOT=DEBUG
```

This merges the specified keys into the base ConfigMap while preserving all other keys.
