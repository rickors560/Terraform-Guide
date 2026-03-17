# Documentation

Comprehensive documentation for the Terraform AWS Guide, organized as a progressive learning path from Terraform basics through production-grade AWS infrastructure patterns.

## Directory Structure

```
docs/
├── 01-terraform-basics/
│   ├── what-is-terraform.md
│   ├── installation-setup.md
│   ├── hcl-syntax.md
│   ├── terraform-cli-commands.md
│   ├── providers.md
│   ├── state-management.md
│   └── backends.md
│
├── 02-terraform-intermediate/
│   ├── variables-and-outputs.md
│   ├── data-sources.md
│   ├── modules.md
│   ├── functions-and-expressions.md
│   ├── workspaces.md
│   ├── provisioners.md
│   └── terraform-cloud.md
│
├── 03-terraform-advanced/
│   ├── testing.md
│   ├── import-existing.md
│   ├── moved-blocks.md
│   ├── custom-providers.md
│   ├── dependency-management.md
│   ├── performance-optimization.md
│   └── security-best-practices.md
│
├── 04-aws-services-guide/
│   ├── networking.md
│   ├── networking-advanced.md
│   ├── compute.md
│   ├── containers.md
│   ├── databases.md
│   ├── storage.md
│   ├── security.md
│   ├── monitoring.md
│   ├── messaging.md
│   ├── serverless.md
│   └── cost-management.md
│
├── 05-cicd/
│   ├── cicd-overview.md
│   ├── github-actions-terraform.md
│   ├── atlantis.md
│   ├── terraform-cloud-vcs.md
│   ├── pipeline-security.md
│   └── drift-detection.md
│
├── 06-kubernetes/
│   ├── eks-overview.md
│   ├── eks-terraform.md
│   ├── k8s-manifests-guide.md
│   ├── helm-with-terraform.md
│   ├── ingress-and-dns.md
│   ├── autoscaling.md
│   ├── observability.md
│   └── service-mesh.md
│
├── 07-production-patterns/
│   ├── multi-environment.md
│   ├── tagging-strategy.md
│   ├── secrets-management.md
│   ├── blue-green-canary.md
│   ├── disaster-recovery.md
│   ├── compliance-and-governance.md
│   └── cost-optimization.md
│
└── 08-workflows/
    ├── developer-workflow.md
    ├── onboarding-guide.md
    ├── incident-response.md
    └── runbook-template.md
```

**Total: 57 documents across 8 sections**

## Learning Path

The documentation is organized as a progressive learning path. Each section builds on the previous ones.

```
┌──────────────────────────────────────────────────────────────────┐
│  BEGINNER                                                        │
│  01-terraform-basics ──> 02-terraform-intermediate               │
│  (What is Terraform,     (Modules, variables,                    │
│   HCL, state, CLI)        data sources, workspaces)              │
└──────────────────────────┬───────────────────────────────────────┘
                           │
┌──────────────────────────▼───────────────────────────────────────┐
│  INTERMEDIATE                                                     │
│  03-terraform-advanced ──> 04-aws-services-guide                 │
│  (Testing, imports,        (Networking, compute, DB,             │
│   performance, security)    storage, all AWS services)           │
└──────────────────────────┬───────────────────────────────────────┘
                           │
┌──────────────────────────▼───────────────────────────────────────┐
│  ADVANCED                                                         │
│  05-cicd ──> 06-kubernetes ──> 07-production-patterns            │
│  (Pipelines,  (EKS, Helm,      (Multi-env, DR,                  │
│   GitOps)      service mesh)     compliance, cost)               │
└──────────────────────────┬───────────────────────────────────────┘
                           │
┌──────────────────────────▼───────────────────────────────────────┐
│  PRACTITIONER                                                     │
│  08-workflows                                                     │
│  (Developer workflows, onboarding, incident response, runbooks)  │
└──────────────────────────────────────────────────────────────────┘
```

## Section Descriptions

### [01 - Terraform Basics](./01-terraform-basics/)
**7 documents** -- Start here. Covers what Terraform is, how to install it, HCL syntax fundamentals, CLI commands, providers, state management, and backend configuration. No prior Terraform experience required.

### [02 - Terraform Intermediate](./02-terraform-intermediate/)
**7 documents** -- Variables, outputs, data sources, modules, built-in functions, workspaces, provisioners, and Terraform Cloud. Builds directly on the basics.

### [03 - Terraform Advanced](./03-terraform-advanced/)
**7 documents** -- Testing strategies, importing existing infrastructure, refactoring with moved blocks, custom providers, dependency management, performance optimization, and security best practices.

### [04 - AWS Services Guide](./04-aws-services-guide/)
**11 documents** -- Deep-dive into every AWS service category managed by this repository: networking, compute, containers, databases, storage, security, monitoring, messaging, serverless, and cost management. Maps directly to the modules in `modules/`.

### [05 - CI/CD](./05-cicd/)
**6 documents** -- Automating Terraform with CI/CD pipelines. Covers GitHub Actions, Atlantis, Terraform Cloud VCS integration, pipeline security, and drift detection.

### [06 - Kubernetes](./06-kubernetes/)
**8 documents** -- Running Kubernetes on AWS with EKS. Covers cluster provisioning with Terraform, manifest management, Helm charts, ingress, autoscaling, observability, and service mesh.

### [07 - Production Patterns](./07-production-patterns/)
**7 documents** -- Patterns for running Terraform at scale in production. Multi-environment strategies, tagging, secrets, blue-green/canary deployments, disaster recovery, compliance, and cost optimization.

### [08 - Workflows](./08-workflows/)
**4 documents** -- Day-to-day operational workflows. Developer workflow guide, team onboarding, incident response procedures, and a runbook template for operational tasks.

## Suggested Reading Order

**If you are new to Terraform:**
1. Start with `01-terraform-basics/` (all 7 files in order)
2. Continue to `02-terraform-intermediate/` (all 7 files in order)
3. Try deploying the `components/vpc` component hands-on
4. Read `04-aws-services-guide/networking.md` for context
5. Continue through sections 03-08

**If you know Terraform but are new to this repository:**
1. Read `08-workflows/developer-workflow.md` first
2. Skim `04-aws-services-guide/` for the services you need
3. Read `07-production-patterns/multi-environment.md`
4. Refer to `03-terraform-advanced/` as needed

**If you are onboarding a new team member:**
1. Have them read `08-workflows/onboarding-guide.md`
2. Walk through `01-terraform-basics/` and `02-terraform-intermediate/`
3. Deploy `components/vpc` and `components/ec2` together as practice
4. Point them to `05-cicd/` for understanding the deployment pipeline

## Cross-References to Hands-On Examples

| Documentation Section | Related Modules | Related Components |
|---|---|---|
| 01-terraform-basics | `modules/networking/vpc` (examples/) | `components/vpc` |
| 04-aws-services-guide/networking | `modules/networking/*` | `components/vpc`, `components/alb`, `components/route53` |
| 04-aws-services-guide/compute | `modules/compute/*` | `components/ec2`, `components/lambda` |
| 04-aws-services-guide/containers | `modules/containers/*` | `components/eks`, `components/ecs-fargate`, `components/ecr` |
| 04-aws-services-guide/databases | `modules/database/*` | `components/rds`, `components/aurora`, `components/dynamodb` |
| 04-aws-services-guide/storage | `modules/storage/*` | `components/s3`, `components/ebs`, `components/efs` |
| 04-aws-services-guide/security | `modules/security/*` | `components/iam`, `components/kms`, `components/waf` |
| 05-cicd | `modules/cicd/*` | -- |
| 06-kubernetes | `modules/containers/eks/*` | `components/eks` |
| 07-production-patterns | All modules | All components |
