# Helm Chart -- MyApp

A Helm chart for deploying the MyApp full-stack application (Spring Boot backend + React/nginx frontend) on Kubernetes. This chart is an alternative to the Kustomize manifests in `k8s/base/` and `k8s/overlays/`.

## Chart Structure

```
app-chart/
├── Chart.yaml                    # Chart metadata (name: myapp, version: 1.0.0, appVersion: 1.0.0)
├── values.yaml                   # Default values (dev-like configuration)
├── values-dev.yaml               # Dev environment overrides
├── values-staging.yaml           # Staging environment overrides
├── values-prod.yaml              # Production environment overrides
└── templates/
    ├── _helpers.tpl              # Template helper functions (naming, labels, image tags)
    ├── deployment-backend.yaml   # Backend Deployment (conditionally rendered)
    ├── deployment-frontend.yaml  # Frontend Deployment (conditionally rendered)
    ├── service-backend.yaml      # Backend ClusterIP Service (8080 + 8081)
    ├── service-frontend.yaml     # Frontend ClusterIP Service (80)
    ├── configmap.yaml            # Backend ConfigMap from values
    ├── secret.yaml               # Optional Secret (pre-install hook, base64-encoded)
    ├── ingress.yaml              # ALB Ingress (conditionally rendered)
    ├── hpa.yaml                  # HorizontalPodAutoscaler (conditionally rendered)
    ├── serviceaccount.yaml       # Backend ServiceAccount with IRSA
    └── NOTES.txt                 # Post-install help text (URLs, useful commands)
```

## Install / Upgrade / Rollback

```bash
# Install for dev
helm install myapp k8s/helm/app-chart \
  -f k8s/helm/app-chart/values-dev.yaml \
  -n myapp --create-namespace

# Install for staging
helm install myapp k8s/helm/app-chart \
  -f k8s/helm/app-chart/values-staging.yaml \
  -n myapp --create-namespace

# Install for production
helm install myapp k8s/helm/app-chart \
  -f k8s/helm/app-chart/values-prod.yaml \
  -n myapp --create-namespace

# Upgrade an existing release
helm upgrade myapp k8s/helm/app-chart \
  -f k8s/helm/app-chart/values-prod.yaml \
  -n myapp

# Upgrade with a specific image tag
helm upgrade myapp k8s/helm/app-chart \
  -f k8s/helm/app-chart/values-prod.yaml \
  --set backend.image.tag=abc12345 \
  --set frontend.image.tag=abc12345 \
  -n myapp

# Rollback to the previous release
helm rollback myapp -n myapp

# Rollback to a specific revision
helm rollback myapp 3 -n myapp

# View release history
helm history myapp -n myapp

# Preview rendered templates without installing
helm template myapp k8s/helm/app-chart \
  -f k8s/helm/app-chart/values-prod.yaml \
  -n myapp

# Uninstall
helm uninstall myapp -n myapp
```

## Values Files

| File | Purpose |
|---|---|
| `values.yaml` | Default values with dev-like settings. All configurable parameters are defined here. |
| `values-dev.yaml` | Dev overrides: 1 replica each, small resources, HPA disabled, DEBUG logging, topology spread disabled, monitoring disabled |
| `values-staging.yaml` | Staging overrides: 2 replicas each, HPA enabled (backend 2-6, frontend 2-4), INFO logging, monitoring and ServiceMonitor enabled |
| `values-prod.yaml` | Prod overrides: 3 replicas each, large resources, HPA enabled (backend 3-20, frontend 3-10), WARN logging, pod anti-affinity, JVM tuning, WAFv2 + Shield, ALB access logging, ServiceMonitor at 15s interval |

## Key Template Features

- **Conditional rendering**: Backend, frontend, ingress, HPA, secrets, and ServiceMonitor can each be enabled/disabled via `*.enabled` values
- **Helper functions** (`_helpers.tpl`): Generates consistent names (`myapp.fullname`, `myapp.backend.fullname`), labels (common, selector, per-component), and image references (with optional registry prefix)
- **ConfigMap checksum**: The backend Deployment includes a `checksum/config` annotation that triggers a rolling restart when ConfigMap values change
- **Secret management**: Optional Secret resource created as a Helm pre-install/pre-upgrade hook. Comments in the template reference ExternalSecret as the recommended production approach.
- **Image registry support**: `global.imageRegistry` prepends a registry prefix to all image references (useful for ECR)
- **Extra environment variables**: `backend.extraEnv` allows injecting additional env vars (used in prod for JVM options)
- **Full probe configurability**: Startup, readiness, and liveness probe timings are all configurable via values

## When to Use Helm vs Kustomize

| Consideration | Helm | Kustomize |
|---|---|---|
| Release management (history, rollback) | Built-in | Manual |
| Value parameterization | Native (Go templates) | Limited (patches, configMapGenerator) |
| Tooling required | `helm` CLI | `kubectl` (built-in) |
| Template complexity | Can be hard to debug | Plain YAML with patches |
| Dependency management | `Chart.yaml` dependencies | None |
| CI/CD integration | `helm upgrade --install` | `kubectl apply -k` |
| Secrets handling | Helm hooks, helm-secrets plugin | External tooling |

Use **Kustomize** when you prefer staying close to raw Kubernetes YAML and managing differences as small patches. Use **Helm** when you need release lifecycle management, dynamic value injection from CI/CD pipelines, or complex conditional logic in templates.
