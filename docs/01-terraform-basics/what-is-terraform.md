# What is Terraform?

## Table of Contents

- [Infrastructure as Code (IaC)](#infrastructure-as-code-iac)
- [What is Terraform](#what-is-terraform)
- [Terraform Architecture](#terraform-architecture)
- [Declarative vs Imperative](#declarative-vs-imperative)
- [Terraform vs Alternatives](#terraform-vs-alternatives)
- [Core Use Cases](#core-use-cases)
- [Benefits of Terraform](#benefits-of-terraform)
- [How Terraform Works](#how-terraform-works)
- [The Terraform Ecosystem](#the-terraform-ecosystem)

---

## Infrastructure as Code (IaC)

Infrastructure as Code is the practice of managing and provisioning computing infrastructure through machine-readable configuration files rather than manual processes or interactive tools. IaC brings software engineering practices to infrastructure management:

- **Version Control**: Track every change to your infrastructure in Git.
- **Code Review**: Infrastructure changes go through the same review process as application code.
- **Reproducibility**: Create identical environments on demand.
- **Automation**: Eliminate manual clicks in cloud consoles.
- **Documentation**: The code itself documents what infrastructure exists and how it is configured.

Without IaC, teams face configuration drift, undocumented changes, snowflake servers, and slow, error-prone provisioning. IaC resolves these problems by making infrastructure deterministic and repeatable.

---

## What is Terraform

Terraform is an open-source infrastructure as code tool created by HashiCorp. It lets you define infrastructure in human-readable configuration files that you can version, reuse, and share. Terraform can manage infrastructure across hundreds of cloud providers and services through a plugin-based architecture.

Terraform uses the HashiCorp Configuration Language (HCL) to describe the desired end state of your infrastructure. When you run Terraform, it compares the desired state to the current state and determines what changes need to be made. This is the **plan and apply** workflow:

```
Write Config -> terraform init -> terraform plan -> terraform apply
```

Terraform tracks the real-world state of your infrastructure in a **state file**, which acts as the source of truth for what Terraform manages. This state file enables Terraform to determine what needs to be created, updated, or destroyed on each run.

---

## Terraform Architecture

Terraform has three fundamental components that work together:

```
+---------------------------------------------------+
|                  Terraform CLI                      |
|                                                     |
|  +-------------+  +-----------+  +---------------+  |
|  | Terraform   |  |  State    |  | Configuration |  |
|  | Core        |  |  Manager  |  | Parser (HCL)  |  |
|  +------+------+  +-----+-----+  +-------+-------+  |
|         |               |                |           |
|         +-------+-------+--------+-------+           |
|                 |                                     |
+---------------------------------------------------+
                  |
    +-------------+-------------+
    |             |             |
+---v---+   +----v----+   +----v----+
|  AWS  |   |  Azure  |   |  GCP    |
|Provider|  |Provider |   |Provider |  ... 3000+ providers
+---+---+   +----+----+   +----+----+
    |             |             |
+---v---+   +----v----+   +----v----+
|  AWS  |   |  Azure  |   |  GCP    |
|  APIs |   |  APIs   |   |  APIs   |
+-------+   +---------+   +---------+
```

### Terraform Core

The core binary (`terraform`) is responsible for:

- Reading and parsing HCL configuration files
- Building a resource dependency graph
- Executing the plan/apply lifecycle
- Managing the state file
- Communicating with providers via RPC

### Providers

Providers are plugins that let Terraform interact with external APIs. Each provider exposes a set of **resources** (things to create) and **data sources** (things to read). The Terraform Registry hosts over 3,000 providers including:

| Provider | Purpose |
|----------|---------|
| `hashicorp/aws` | Amazon Web Services |
| `hashicorp/azurerm` | Microsoft Azure |
| `hashicorp/google` | Google Cloud Platform |
| `hashicorp/kubernetes` | Kubernetes clusters |
| `hashicorp/helm` | Helm charts |
| `integrations/github` | GitHub repositories and teams |
| `hashicorp/vault` | HashiCorp Vault secrets |
| `cloudflare/cloudflare` | Cloudflare DNS and CDN |

### State

Terraform state is a JSON file that maps your configuration to the real-world resources it manages. State enables Terraform to:

- Know what resources it controls
- Detect drift between desired and actual state
- Determine the order of operations for changes
- Store resource attributes for use by other resources

---

## Declarative vs Imperative

Understanding this distinction is critical for working effectively with Terraform.

### Imperative Approach

You tell the system **how** to reach a desired state, step by step. If you want three servers, you write a script that creates three servers. If you later want five, you write a new script that creates two more.

```bash
# Imperative: Bash script to create an EC2 instance
aws ec2 run-instances \
  --image-id ami-0abcdef1234567890 \
  --instance-type t3.micro \
  --key-name my-key \
  --subnet-id subnet-0123456789abcdef0
```

**Problem**: This script does not check if the instance already exists. Running it twice creates two instances. You must write all the logic for idempotency, error handling, and state tracking yourself.

### Declarative Approach

You tell the system **what** the desired state is. The tool figures out how to get there.

```hcl
# Declarative: Terraform configuration
resource "aws_instance" "web" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"
  key_name      = "my-key"
  subnet_id     = "subnet-0123456789abcdef0"
}
```

**Benefit**: Run this configuration multiple times and the result is always the same. If the instance exists, Terraform does nothing. If it was deleted, Terraform recreates it. If a property changed, Terraform updates it.

---

## Terraform vs Alternatives

### Terraform vs AWS CloudFormation

| Feature | Terraform | CloudFormation |
|---------|-----------|----------------|
| Cloud support | Multi-cloud (AWS, Azure, GCP, etc.) | AWS only |
| Language | HCL (purpose-built) | JSON/YAML |
| State management | Self-managed or Terraform Cloud | Managed by AWS |
| Drift detection | Via `terraform plan` | Stack drift detection |
| Modularity | Modules with versioning | Nested stacks, StackSets |
| Import existing | `terraform import`, import blocks | `resource import` |
| Preview changes | `terraform plan` (detailed diff) | Change sets |
| Community | Massive OSS community | AWS-maintained |
| Rollback | No automatic rollback | Automatic rollback on failure |

**When to choose CloudFormation**: You are 100% AWS and want zero state management overhead with native rollback support.

**When to choose Terraform**: You need multi-cloud, want a better language, or need to manage non-AWS resources alongside AWS.

### Terraform vs Pulumi

| Feature | Terraform | Pulumi |
|---------|-----------|--------|
| Language | HCL | Python, TypeScript, Go, C#, Java |
| Learning curve | Learn HCL | Use familiar programming language |
| State management | Self-managed or TF Cloud | Pulumi Cloud or self-managed |
| Testing | terraform test, Terratest | Native unit testing in your language |
| IDE support | HCL extensions | Full IDE support for your language |
| Ecosystem | Largest provider ecosystem | Uses Terraform providers via bridge |

**When to choose Pulumi**: Your team prefers writing infrastructure in a general-purpose language and wants native testing capabilities.

**When to choose Terraform**: You want the largest ecosystem, most community examples, and a DSL purpose-built for infrastructure.

### Terraform vs AWS CDK

| Feature | Terraform | AWS CDK |
|---------|-----------|---------|
| Output | Direct API calls via providers | Synthesizes to CloudFormation |
| Cloud support | Multi-cloud | AWS only |
| Language | HCL | TypeScript, Python, Java, C#, Go |
| Abstraction | Resources and modules | Constructs (L1, L2, L3) |
| Maturity | Very mature | Mature for AWS |

**When to choose CDK**: You are all-in on AWS and want high-level abstractions (L2/L3 constructs) that encode AWS best practices.

### Terraform vs Ansible

Terraform and Ansible serve different purposes and are often used together:

- **Terraform**: Provisions infrastructure (VPCs, EC2 instances, RDS databases).
- **Ansible**: Configures servers (installs packages, deploys applications, manages files).

Terraform is declarative and tracks state. Ansible is procedural and does not maintain a state file. Use Terraform to create the server, and Ansible to configure it.

---

## Core Use Cases

### Multi-Cloud Deployment

```hcl
# Deploy to AWS
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "app" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"
}

# Deploy to GCP in the same configuration
provider "google" {
  project = "my-project"
  region  = "us-central1"
}

resource "google_compute_instance" "app" {
  name         = "app-server"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
  }
}
```

### Self-Service Infrastructure

Teams define reusable modules in a private registry. Developers consume modules without needing deep cloud expertise:

```hcl
module "web_app" {
  source  = "app.terraform.io/my-org/web-app/aws"
  version = "2.1.0"

  app_name    = "payment-service"
  environment = "production"
  instance_count = 3
}
```

### Kubernetes and Application Infrastructure

Terraform can provision a Kubernetes cluster and deploy workloads to it:

```hcl
resource "aws_eks_cluster" "main" {
  name     = "production"
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids = module.vpc.private_subnets
  }
}

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress"
}
```

### Compliance and Governance

Using policy-as-code tools like Sentinel or OPA alongside Terraform to enforce organizational standards before infrastructure is provisioned.

---

## Benefits of Terraform

### Platform Agnostic

A single tool and workflow for AWS, Azure, GCP, Kubernetes, GitHub, Datadog, PagerDuty, and thousands of other services. Your team learns one tool instead of many.

### Dependency Graph

Terraform automatically determines the order of operations. If a subnet depends on a VPC, Terraform creates the VPC first. This graph also enables parallel creation of independent resources, improving apply speed.

### Plan Before Apply

The `terraform plan` command shows exactly what will change before anything is modified. This preview capability is essential for safe infrastructure management in production environments.

### Idempotent Operations

Running `terraform apply` multiple times with the same configuration always results in the same infrastructure state. Terraform only makes changes when the configuration differs from the current state.

### Ecosystem and Community

- 3,000+ providers in the Terraform Registry
- Thousands of published modules
- Active community forums, Stack Overflow, and GitHub discussions
- Extensive documentation and learning resources

---

## How Terraform Works

The Terraform workflow has four main phases:

### 1. Write

Define your infrastructure in `.tf` files using HCL:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "data" {
  bucket = "my-application-data-bucket"
}
```

### 2. Initialize

`terraform init` downloads the required providers and sets up the backend:

```
$ terraform init
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.31.0...
Terraform has been successfully initialized!
```

### 3. Plan

`terraform plan` compares your configuration to the current state and shows what will change:

```
$ terraform plan
Terraform will perform the following actions:

  # aws_s3_bucket.data will be created
  + resource "aws_s3_bucket" "data" {
      + bucket = "my-application-data-bucket"
      + id     = (known after apply)
      + arn    = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

### 4. Apply

`terraform apply` executes the plan and provisions the infrastructure:

```
$ terraform apply
aws_s3_bucket.data: Creating...
aws_s3_bucket.data: Creation complete after 2s [id=my-application-data-bucket]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

---

## The Terraform Ecosystem

### Terraform CLI (Open Source)

The core tool. Free and open source. You manage state, execution, and collaboration yourself.

### Terraform Cloud / HCP Terraform

A SaaS platform from HashiCorp that provides:

- Remote state storage with encryption and locking
- Remote plan and apply execution
- VCS-driven workflows (trigger runs on Git push)
- Policy enforcement with Sentinel
- Cost estimation
- Private module registry
- Team and organization management

### Terraform Enterprise

Self-hosted version of Terraform Cloud for organizations with strict compliance requirements that need to run everything within their own network.

### Terraform CDK (CDKTF)

Write Terraform configurations using TypeScript, Python, Java, C#, or Go. CDKTF synthesizes your code into standard Terraform JSON configuration.

```typescript
import { App, TerraformStack } from "cdktf";
import { AwsProvider } from "@cdktf/provider-aws/lib/provider";
import { S3Bucket } from "@cdktf/provider-aws/lib/s3-bucket";

class MyStack extends TerraformStack {
  constructor(scope: Construct, id: string) {
    super(scope, id);
    new AwsProvider(this, "aws", { region: "us-east-1" });
    new S3Bucket(this, "bucket", { bucket: "my-cdktf-bucket" });
  }
}

const app = new App();
new MyStack(app, "my-stack");
app.synth();
```

### OpenTofu

An open-source fork of Terraform maintained by the Linux Foundation, created after HashiCorp changed Terraform's license from MPL to BSL in August 2023. OpenTofu aims to remain fully open source and is largely compatible with Terraform configurations.

---

## Next Steps

Now that you understand what Terraform is and where it fits in the IaC landscape, proceed to:

- [Installation and Setup](installation-setup.md) to get Terraform running on your machine
- [HCL Syntax](hcl-syntax.md) to learn the configuration language
- [Terraform CLI Commands](terraform-cli-commands.md) to master the command-line workflow
