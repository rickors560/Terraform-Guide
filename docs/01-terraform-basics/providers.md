# Providers

## Table of Contents

- [What are Providers](#what-are-providers)
- [Provider Configuration](#provider-configuration)
- [Provider Versioning](#provider-versioning)
- [The required_providers Block](#the-required_providers-block)
- [Provider Source Addresses](#provider-source-addresses)
- [Alias Providers](#alias-providers)
- [Multi-Region Deployments](#multi-region-deployments)
- [Multi-Account Deployments](#multi-account-deployments)
- [Provider Authentication](#provider-authentication)
- [Provider Installation and Caching](#provider-installation-and-caching)
- [Commonly Used Providers](#commonly-used-providers)
- [Provider Best Practices](#provider-best-practices)

---

## What are Providers

Providers are plugins that allow Terraform to interact with external APIs and services. Each provider offers a set of **resource types** (things you create and manage) and **data sources** (things you read). Without providers, Terraform cannot do anything.

When you declare a resource like `aws_instance`, the `aws` prefix identifies the provider. Terraform uses the AWS provider plugin to translate your configuration into AWS API calls.

```
+-------------------+       +-----------------+       +------------+
| Terraform Config  | ----> | AWS Provider    | ----> | AWS API    |
| (HCL files)       |       | (Plugin binary) |       | (EC2, S3)  |
+-------------------+       +-----------------+       +------------+
```

The Terraform Registry at [registry.terraform.io](https://registry.terraform.io) hosts over 3,000 providers, including official providers maintained by HashiCorp, partner providers maintained by technology companies, and community providers maintained by individuals.

---

## Provider Configuration

Provider configuration tells Terraform how to authenticate and interact with the target API.

### Basic Configuration

```hcl
provider "aws" {
  region = "us-east-1"
}
```

### Full AWS Provider Configuration

```hcl
provider "aws" {
  region  = "us-east-1"
  profile = "production"

  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Project     = "web-platform"
      Environment = "production"
    }
  }

  # Ignore specific tags applied outside Terraform
  ignore_tags {
    key_prefixes = ["kubernetes.io/"]
  }

  # Assume a role for cross-account access
  assume_role {
    role_arn     = "arn:aws:iam::987654321098:role/TerraformRole"
    session_name = "terraform-production"
    external_id  = "unique-external-id"
  }
}
```

### Provider Configuration for Other Clouds

```hcl
# Google Cloud
provider "google" {
  project     = "my-gcp-project"
  region      = "us-central1"
  credentials = file("service-account.json")
}

# Azure
provider "azurerm" {
  features {}

  subscription_id = "00000000-0000-0000-0000-000000000000"
  tenant_id       = "00000000-0000-0000-0000-000000000000"
}

# Kubernetes
provider "kubernetes" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}
```

---

## Provider Versioning

Provider versions follow semantic versioning (MAJOR.MINOR.PATCH). Constraining provider versions ensures consistent behavior across your team and CI/CD pipelines.

### Version Constraint Syntax

| Constraint | Meaning | Example |
|------------|---------|---------|
| `= 5.31.0` | Exact version only | Only 5.31.0 |
| `>= 5.0` | Minimum version | 5.0 or higher |
| `~> 5.0` | Pessimistic constraint (allows only patch/minor updates) | >= 5.0.0, < 6.0.0 |
| `~> 5.31` | Allows only patch updates | >= 5.31.0, < 5.32.0 |
| `>= 5.0, < 6.0` | Range | Any 5.x version |

### Recommended Approach

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"    # Allow any 5.x version
    }
  }
}
```

The `~>` operator is the most commonly used. `~> 5.0` means "any version in the 5.x series." This allows patch and minor updates (which should be backwards-compatible) while preventing major version upgrades that may contain breaking changes.

### The Dependency Lock File

When you run `terraform init`, Terraform records the exact provider versions in `.terraform.lock.hcl`:

```hcl
# This file is maintained automatically by "terraform init".
provider "registry.terraform.io/hashicorp/aws" {
  version     = "5.31.0"
  constraints = "~> 5.0"
  hashes = [
    "h1:abc123...",
    "zh:def456...",
  ]
}
```

**Always commit `.terraform.lock.hcl` to version control.** It ensures every team member and CI/CD pipeline uses the exact same provider version, even if a newer version is released that satisfies the constraint.

### Upgrading Providers

```bash
# Upgrade all providers to the latest version allowed by constraints
terraform init -upgrade

# After upgrading, review the changes
terraform plan
```

---

## The required_providers Block

The `required_providers` block inside the `terraform` block declares which providers your configuration needs, where to find them, and what versions are acceptable.

```hcl
terraform {
  required_providers {
    # Official HashiCorp provider
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    # Partner provider
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.30"
    }

    # Community provider
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }

    # Provider with a custom local name
    mycloud = {
      source  = "example/mycloud"
      version = ">= 1.0"
    }
  }
}
```

### Local Name vs Source

The key in `required_providers` (e.g., `aws`, `datadog`) is the **local name** used to reference the provider in your configuration. The `source` is the global address in the registry. They usually match, but you can use a custom local name:

```hcl
terraform {
  required_providers {
    # Using "hashicorp_aws" as the local name
    hashicorp_aws = {
      source = "hashicorp/aws"
    }
  }
}

# Reference uses the local name
provider "hashicorp_aws" {
  region = "us-east-1"
}
```

---

## Provider Source Addresses

Provider source addresses have three components:

```
<hostname>/<namespace>/<type>
```

| Component | Description | Example |
|-----------|-------------|---------|
| `hostname` | Registry hostname (default: `registry.terraform.io`) | `registry.terraform.io` |
| `namespace` | Organization or user | `hashicorp`, `integrations` |
| `type` | Provider name | `aws`, `github` |

### Examples

```hcl
# Full address (explicit hostname)
source = "registry.terraform.io/hashicorp/aws"

# Short form (registry.terraform.io is implied)
source = "hashicorp/aws"

# Private registry
source = "app.terraform.io/my-org/custom-provider"

# Local filesystem (for development)
source = "example.com/myorg/myprovider"
```

### Using a Private Registry

For organizations that host their own providers:

```hcl
terraform {
  required_providers {
    internal = {
      source  = "terraform.mycompany.com/platform/internal"
      version = "~> 2.0"
    }
  }
}
```

Configure the CLI to authenticate with the private registry in `~/.terraformrc`:

```hcl
credentials "terraform.mycompany.com" {
  token = "your-api-token"
}
```

---

## Alias Providers

When you need multiple configurations of the same provider, use aliases. This is essential for multi-region and multi-account deployments.

```hcl
# Default provider (no alias)
provider "aws" {
  region = "us-east-1"
}

# Additional provider with alias
provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

# Another alias for a different account
provider "aws" {
  alias   = "security"
  region  = "us-east-1"
  profile = "security-account"
}
```

### Using Aliased Providers in Resources

```hcl
# Uses the default provider (us-east-1)
resource "aws_instance" "east_server" {
  ami           = "ami-east-123"
  instance_type = "t3.micro"
}

# Uses the aliased provider (us-west-2)
resource "aws_instance" "west_server" {
  provider      = aws.west
  ami           = "ami-west-456"
  instance_type = "t3.micro"
}
```

### Using Aliased Providers in Modules

```hcl
module "west_vpc" {
  source = "./modules/vpc"

  providers = {
    aws = aws.west
  }

  cidr_block = "10.1.0.0/16"
}
```

Inside the module, resources use the default `aws` provider, but it is mapped to the `aws.west` configuration from the calling module.

---

## Multi-Region Deployments

A common pattern for deploying infrastructure across multiple AWS regions:

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu"
  region = "eu-west-1"
}

provider "aws" {
  alias  = "ap"
  region = "ap-southeast-1"
}

# Deploy the same module in multiple regions
module "app_us" {
  source = "./modules/app"

  providers = {
    aws = aws
  }

  environment = "production"
  region_name = "us"
}

module "app_eu" {
  source = "./modules/app"

  providers = {
    aws = aws.eu
  }

  environment = "production"
  region_name = "eu"
}

module "app_ap" {
  source = "./modules/app"

  providers = {
    aws = aws.ap
  }

  environment = "production"
  region_name = "ap"
}
```

### Global Resources Pattern

Some resources (CloudFront, WAF, Route53) must be created in `us-east-1`. Use aliased providers to handle this:

```hcl
provider "aws" {
  region = "eu-west-1"   # Primary region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"   # For global resources
}

# ACM certificate for CloudFront must be in us-east-1
resource "aws_acm_certificate" "cdn" {
  provider          = aws.us_east_1
  domain_name       = "cdn.example.com"
  validation_method = "DNS"
}

resource "aws_cloudfront_distribution" "cdn" {
  # CloudFront is a global service, but uses us-east-1 certificates
  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cdn.arn
    ssl_support_method  = "sni-only"
  }

  # ... rest of configuration
}
```

---

## Multi-Account Deployments

### Using Assume Role

```hcl
# Management account (where Terraform runs)
provider "aws" {
  region = "us-east-1"
}

# Development account
provider "aws" {
  alias  = "dev"
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::111111111111:role/TerraformRole"
  }
}

# Production account
provider "aws" {
  alias  = "prod"
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::222222222222:role/TerraformRole"
  }
}

# Create resources in different accounts
resource "aws_s3_bucket" "dev_data" {
  provider = aws.dev
  bucket   = "dev-application-data"
}

resource "aws_s3_bucket" "prod_data" {
  provider = aws.prod
  bucket   = "prod-application-data"
}
```

### Using Named Profiles

```hcl
provider "aws" {
  alias   = "dev"
  region  = "us-east-1"
  profile = "dev-account"
}

provider "aws" {
  alias   = "prod"
  region  = "us-east-1"
  profile = "prod-account"
}
```

---

## Provider Authentication

### AWS Provider Authentication Methods

The AWS provider checks credentials in this order:

1. **Static credentials in provider block** (not recommended)

```hcl
provider "aws" {
  access_key = "AKIAIOSFODNN7EXAMPLE"     # DO NOT hardcode
  secret_key = "wJalrXUtnFEMI/K7MDENG"    # DO NOT hardcode
  region     = "us-east-1"
}
```

2. **Environment variables**

```bash
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."    # for temporary credentials
export AWS_REGION="us-east-1"
```

3. **Shared credentials file** (`~/.aws/credentials`)

4. **Shared config file** (`~/.aws/config`) with a profile

5. **EC2 Instance Metadata / ECS Task Role / EKS Pod Identity**

6. **SSO credentials**

For CI/CD pipelines, use OIDC federation or IAM roles. Never store long-lived credentials in environment variables or configuration files in CI systems.

---

## Provider Installation and Caching

### Plugin Cache

To avoid downloading the same provider binaries repeatedly, configure a plugin cache:

```bash
# Set in environment
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
mkdir -p "$TF_PLUGIN_CACHE_DIR"
```

Or in `~/.terraformrc`:

```hcl
plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
```

### Air-Gapped Environments

For environments without internet access, mirror providers locally:

```bash
# Mirror providers to a directory
terraform providers mirror /path/to/mirror

# Use the mirror as a filesystem source
# In ~/.terraformrc:
```

```hcl
provider_installation {
  filesystem_mirror {
    path    = "/path/to/mirror"
    include = ["registry.terraform.io/*/*"]
  }
}
```

---

## Commonly Used Providers

| Provider | Source | Purpose |
|----------|--------|---------|
| AWS | `hashicorp/aws` | Amazon Web Services resources |
| Azure | `hashicorp/azurerm` | Microsoft Azure resources |
| Google | `hashicorp/google` | Google Cloud Platform resources |
| Kubernetes | `hashicorp/kubernetes` | Kubernetes resources |
| Helm | `hashicorp/helm` | Helm chart deployments |
| Docker | `kreuzwerker/docker` | Docker containers and images |
| GitHub | `integrations/github` | GitHub repos, teams, actions |
| Cloudflare | `cloudflare/cloudflare` | DNS, CDN, security |
| Datadog | `DataDog/datadog` | Monitoring dashboards and alerts |
| Vault | `hashicorp/vault` | Secrets management |
| Random | `hashicorp/random` | Random values (IDs, passwords, pets) |
| Null | `hashicorp/null` | Null resources and provisioners |
| Local | `hashicorp/local` | Local files |
| TLS | `hashicorp/tls` | TLS certificates and keys |
| Archive | `hashicorp/archive` | ZIP archives for Lambda, etc. |
| External | `hashicorp/external` | External data sources (scripts) |

---

## Provider Best Practices

### 1. Always Pin Provider Versions

```hcl
# Good: constrained version
aws = {
  source  = "hashicorp/aws"
  version = "~> 5.0"
}

# Bad: no version constraint (uses latest, may break)
aws = {
  source = "hashicorp/aws"
}
```

### 2. Commit the Lock File

Always commit `.terraform.lock.hcl` so everyone uses the same provider version.

### 3. Use Default Tags

Avoid repeating tags on every resource:

```hcl
provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Terraform   = "true"
      Environment = var.environment
      Team        = var.team
    }
  }
}
```

### 4. Separate Provider Configuration from Resources

Keep provider blocks in a dedicated `providers.tf` file for clarity.

### 5. Use Variables for Provider Configuration

```hcl
variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

provider "aws" {
  region = var.aws_region
}
```

### 6. Never Hardcode Credentials

Use environment variables, IAM roles, or a credentials file. Never put access keys in `.tf` files.

### 7. Minimize Provider Aliases

Each aliased provider adds complexity. Use modules to encapsulate multi-region or multi-account logic rather than scattering aliases throughout your configuration.

---

## Next Steps

- [Backends](backends.md) for configuring where state is stored
- [Modules](../02-terraform-intermediate/modules.md) for passing providers to modules
- [Security Best Practices](../03-terraform-advanced/security-best-practices.md) for provider authentication patterns
