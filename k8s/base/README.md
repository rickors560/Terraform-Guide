# Kustomize Base Manifests

Base Kustomize manifests for the MyApp application. These define the complete Kubernetes resource set with production-grade defaults. Environment-specific overlays in `k8s/overlays/` customize these base manifests via strategic merge patches.

## Files

| File | Kind | Description |
|---|---|---|
| `kustomization.yaml` | Kustomization | Lists all resources, sets the `myapp` namespace, and applies common labels (`app.kubernetes.io/managed-by: kustomize`, `app.kubernetes.io/part-of: myapp`) |
| `namespace.yaml` | Namespace | Creates the `myapp` namespace with Pod Security Standards set to `restricted` (enforce, audit, warn) |
| `ingress.yaml` | Ingress | AWS ALB Ingress: internet-facing, IP target type, HTTP-to-HTTPS redirect, routes `/api` to backend:8080 and `/` to frontend:80, health checks on `/health` |
| `network-policies.yaml` | NetworkPolicy | Six policies implementing a zero-trust network model (see below) |
| `backend/deployment.yaml` | Deployment | Backend application deployment (see details below) |
| `backend/service.yaml` | Service | ClusterIP exposing port 8080 (application) and 8081 (management/Prometheus metrics) |
| `backend/hpa.yaml` | HorizontalPodAutoscaler | Scales 2-10 replicas targeting 70% CPU and 80% memory, with conservative scale-down (300s stabilization, min of 1 pod or 10% per 60s) and aggressive scale-up (30s stabilization, max of 2 pods or 50% per 60s) |
| `backend/pdb.yaml` | PodDisruptionBudget | Requires at least 1 backend pod available during voluntary disruptions (node drains, upgrades) |
| `backend/configmap.yaml` | ConfigMap | Spring Boot environment variables: `SPRING_PROFILES_ACTIVE=default`, `SERVER_PORT=8080`, `MANAGEMENT_SERVER_PORT=8081`, logging configuration, CORS origins, cache TTL, pagination defaults |
| `backend/serviceaccount.yaml` | ServiceAccount | Annotated with `eks.amazonaws.com/role-arn` for IRSA, enabling the backend pods to assume an IAM role for AWS API access (S3, Secrets Manager) |
| `frontend/deployment.yaml` | Deployment | Frontend application deployment (see details below) |
| `frontend/service.yaml` | Service | ClusterIP exposing port 80 mapped to container port 8080 (nginx) |
| `frontend/hpa.yaml` | HorizontalPodAutoscaler | Scales 2-6 replicas targeting 70% CPU, with conservative scale-down (300s stabilization) |

## Backend Deployment Details

- **Replicas**: 2 (base default, overridden per environment)
- **Strategy**: RollingUpdate with `maxSurge: 1`, `maxUnavailable: 0` (zero-downtime deployments)
- **Image**: `myapp/backend:latest`
- **Ports**: 8080 (HTTP), 8081 (management/metrics)
- **Probes**:
  - Startup: `GET /actuator/health/liveness` on management port, 10s initial delay, 30 failure threshold (allows up to 160s for JVM warmup)
  - Readiness: `GET /actuator/health/readiness` on management port, 10s period
  - Liveness: `GET /actuator/health/liveness` on management port, 15s period
- **Security Context**:
  - Pod: `runAsNonRoot: true`, `runAsUser: 1000`, `runAsGroup: 1000`, `fsGroup: 1000`, `seccompProfile: RuntimeDefault`
  - Container: `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true`, `capabilities.drop: ALL`
- **Resource Defaults**: 500m/512Mi requests, 1000m/1Gi limits
- **Topology Spread**: Spread across zones (`DoNotSchedule`) and hosts (`ScheduleAnyway`)
- **Volumes**: `emptyDir` for `/tmp` (100Mi) and `/var/log/app` (200Mi) to support the read-only root filesystem
- **Prometheus**: Annotations for scraping at `:8081/actuator/prometheus`

## Frontend Deployment Details

- **Replicas**: 2 (base default)
- **Strategy**: RollingUpdate with `maxSurge: 1`, `maxUnavailable: 0`
- **Image**: `myapp/frontend:latest` (nginx serving static React build)
- **Port**: 8080 (nginx configured to listen on 8080, not 80, for non-root)
- **Probes**: All probe on `/health` on the http port
- **Security Context**: `runAsUser: 101` (nginx user), read-only root filesystem, all capabilities dropped
- **Resource Defaults**: 100m/128Mi requests, 500m/256Mi limits
- **Topology Spread**: Spread across zones (`ScheduleAnyway`)
- **Volumes**: `emptyDir` for `/tmp`, `/var/cache/nginx`, `/var/run` (required by nginx with read-only root filesystem)

## Ingress Configuration

The Ingress uses the AWS Load Balancer Controller (ALB IngressClass) with these key annotations:

- `alb.ingress.kubernetes.io/scheme: internet-facing` -- public-facing ALB
- `alb.ingress.kubernetes.io/target-type: ip` -- routes directly to pod IPs (requires VPC CNI)
- `alb.ingress.kubernetes.io/ssl-redirect: "443"` -- redirects HTTP to HTTPS
- `alb.ingress.kubernetes.io/certificate-arn` -- ACM certificate for TLS
- `alb.ingress.kubernetes.io/healthcheck-path: /health` -- ALB health check path
- `alb.ingress.kubernetes.io/group.name: myapp` -- shared ALB via IngressGroup

Routing: `/api` prefix goes to the backend service on port 8080; all other paths go to the frontend on port 80.

## Network Policies

The `network-policies.yaml` implements a zero-trust model with six policies:

1. **default-deny-all** -- Denies all ingress and egress traffic in the namespace (baseline)
2. **allow-dns-egress** -- Allows UDP/TCP port 53 egress for all pods (DNS resolution)
3. **frontend-allow-ingress** -- Allows ingress to frontend pods only from the AWS Load Balancer Controller in kube-system
4. **backend-allow-ingress** -- Allows ingress to backend pods from: frontend pods (port 8080), ALB controller (port 8080), and monitoring namespace (port 8081 for Prometheus scraping)
5. **backend-allow-egress** -- Allows backend egress to: HTTPS (443), PostgreSQL (5432), Redis (6379)
6. **frontend-allow-egress** -- Allows frontend egress only to backend pods on port 8080

## How Base Gets Customized by Overlays

Overlays reference the base via `resources: [../../base]` in their `kustomization.yaml` and apply patches:

- **Replica counts**: Strategic merge patches on Deployment `.spec.replicas`
- **Resource requests/limits**: Patches on container `.resources`
- **Spring profiles**: Both via patch env vars and via `configMapGenerator` with `behavior: merge`
- **Hostnames**: Patches on Ingress `.spec.rules[].host`
- **HPA settings**: Patches on HPA `.spec.minReplicas` and `.spec.maxReplicas`
- **Affinity rules**: Prod overlay adds pod anti-affinity for HA
- **Security features**: Prod overlay adds WAFv2, Shield Advanced, and ALB access logging annotations to the Ingress
- **Name prefixes**: Each overlay applies a `namePrefix` (e.g., `dev-`, `staging-`, `prod-`)
- **Labels**: Each overlay adds an `environment` label via `commonLabels`
