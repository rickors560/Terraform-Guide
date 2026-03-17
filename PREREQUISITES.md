# Prerequisites

Everything you need installed and configured before starting the Terraform AWS Masterclass.

---

## Required Tools

### Terraform

| Tool | Minimum Version | Purpose |
|---|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/install) | `>= 1.9.0` | Infrastructure as Code engine |
| [tfenv](https://github.com/tfutils/tfenv) | Latest | Terraform version manager |

```bash
# Install tfenv
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bashrc

# Install and use the pinned version
tfenv install 1.9.8
tfenv use 1.9.8
terraform version
```

### AWS CLI

| Tool | Minimum Version | Purpose |
|---|---|---|
| [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) | `>= 2.15.0` | AWS API interaction and authentication |

```bash
# Verify installation
aws --version

# Configure a named profile
aws configure --profile terraform-guide
# Region: ap-south-1
# Output: json
```

### Kubernetes Tools

| Tool | Minimum Version | Purpose |
|---|---|---|
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | `>= 1.28` | Kubernetes cluster interaction |
| [Helm](https://helm.sh/docs/intro/install/) | `>= 3.14` | Kubernetes package manager |
| [Kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/) | `>= 5.3` | Kubernetes manifest overlays |

```bash
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Kustomize
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo mv kustomize /usr/local/bin/
```

### Container Tools

| Tool | Minimum Version | Purpose |
|---|---|---|
| [Docker](https://docs.docker.com/get-docker/) | `>= 24.0` | Container builds and local testing |

```bash
docker --version
```

### Application Runtimes

| Tool | Minimum Version | Purpose |
|---|---|---|
| [Node.js](https://nodejs.org/) | `>= 20 LTS` | Frontend application (Next.js) |
| [Java JDK](https://adoptium.net/) | `>= 21` | Backend application (Spring Boot) |
| [Maven](https://maven.apache.org/) | `>= 3.9` | Java build tool |
| [Python](https://www.python.org/) | `>= 3.11` | Scripting, pre-commit hooks |
| [pip](https://pip.pypa.io/) | Latest | Python package manager |

```bash
node --version
java --version
mvn --version
python3 --version
```

### Code Quality and Linting

| Tool | Minimum Version | Purpose |
|---|---|---|
| [pre-commit](https://pre-commit.com/) | `>= 3.6` | Git hook framework |
| [TFLint](https://github.com/terraform-linters/tflint) | `>= 0.50` | Terraform linter |
| [terraform-docs](https://terraform-docs.io/) | `>= 0.18` | Auto-generate module docs |
| [Checkov](https://www.checkov.io/) | `>= 3.2` | Infrastructure security scanner |
| [detect-secrets](https://github.com/Yelp/detect-secrets) | `>= 1.4` | Secret detection in code |
| [tfsec](https://aquasecurity.github.io/tfsec/) | `>= 1.28` | Terraform static security analysis |

```bash
# pre-commit
pip install pre-commit
pre-commit --version

# TFLint
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
tflint --version

# terraform-docs
go install github.com/terraform-docs/terraform-docs@latest
# Or download binary from GitHub releases

# Checkov
pip install checkov
checkov --version

# detect-secrets
pip install detect-secrets
detect-secrets --version
```

### Infrastructure Cost Estimation

| Tool | Minimum Version | Purpose |
|---|---|---|
| [Infracost](https://www.infracost.io/docs/) | `>= 0.10` | Cloud cost estimation for Terraform |

```bash
curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh
infracost --version
infracost auth login
```

### Utilities

| Tool | Minimum Version | Purpose |
|---|---|---|
| [jq](https://stedolan.github.io/jq/) | `>= 1.7` | JSON processing |
| [yq](https://github.com/mikefarah/yq) | `>= 4.40` | YAML processing |
| [Git](https://git-scm.com/) | `>= 2.40` | Version control |
| [Make](https://www.gnu.org/software/make/) | `>= 4.0` | Build automation |

```bash
sudo apt-get install -y jq make git
# or: brew install jq make git

# yq
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq
```

---

## Required Accounts

### AWS Account

- An active AWS account with billing enabled
- An IAM user or role with **AdministratorAccess** for learning purposes (narrow permissions in production)
- MFA enabled on the root account and all IAM users
- Recommended: Use AWS Organizations with a dedicated learning account

### GitHub Account

- A GitHub account for version control
- SSH key or personal access token configured for Git operations
- Required for Phase 9 (CI/CD with GitHub Actions and OIDC federation)

---

## AWS Configuration

### Named Profile

Create a named profile so you never accidentally deploy to the wrong account:

```bash
aws configure --profile terraform-guide

# Set as default for this project
export AWS_PROFILE=terraform-guide
export AWS_DEFAULT_REGION=ap-south-1
```

### Verify Access

```bash
aws sts get-caller-identity --profile terraform-guide
```

Expected output:

```json
{
    "UserId": "AIDEXAMPLEID",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-username"
}
```

---

## Version Verification Script

Run this script to verify all required tools are installed:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "=== Terraform AWS Masterclass — Prerequisite Check ==="
echo ""

check() {
  local name="$1"
  local cmd="$2"
  if command -v "$cmd" &>/dev/null; then
    local version
    version=$("$cmd" --version 2>&1 | head -1)
    printf "  %-20s %s\n" "$name" "$version"
  else
    printf "  %-20s %s\n" "$name" "NOT INSTALLED"
  fi
}

echo "Core Tools:"
check "Terraform" terraform
check "AWS CLI" aws
check "Git" git
check "Make" make
check "Docker" docker

echo ""
echo "Kubernetes Tools:"
check "kubectl" kubectl
check "Helm" helm
check "Kustomize" kustomize

echo ""
echo "Application Runtimes:"
check "Node.js" node
check "Java" java
check "Maven" mvn
check "Python" python3

echo ""
echo "Code Quality:"
check "pre-commit" pre-commit
check "TFLint" tflint
check "terraform-docs" terraform-docs
check "Checkov" checkov
check "detect-secrets" detect-secrets

echo ""
echo "Utilities:"
check "jq" jq
check "yq" yq
check "Infracost" infracost

echo ""
echo "AWS Identity:"
aws sts get-caller-identity 2>/dev/null || echo "  AWS credentials not configured"
```

---

## Estimated AWS Costs

Running the full stack (VPC + EKS + RDS + ElastiCache + ALB + NAT) will incur charges. Approximate costs for the dev environment:

| Resource | Approximate Monthly Cost (ap-south-1) |
|---|---|
| NAT Gateway | ~$35 |
| EKS Control Plane | ~$73 |
| EKS Worker Nodes (2x t3.medium) | ~$60 |
| RDS PostgreSQL (db.t3.micro) | ~$15 |
| ElastiCache Redis (cache.t3.micro) | ~$13 |
| ALB | ~$20 |
| S3 + CloudFront | ~$5 |
| **Total (Dev)** | **~$220/month** |

Always run `make destroy ENV=dev` when you are done to stop charges.
