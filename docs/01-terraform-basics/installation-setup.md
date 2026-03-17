# Installation and Setup

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation on Linux](#installation-on-linux)
- [Installation on macOS](#installation-on-macos)
- [Installation on Windows](#installation-on-windows)
- [Using tfenv for Version Management](#using-tfenv-for-version-management)
- [IDE Setup](#ide-setup)
- [AWS CLI and Credentials Setup](#aws-cli-and-credentials-setup)
- [Verify Installation](#verify-installation)
- [First Project Walkthrough](#first-project-walkthrough)
- [Project Structure Best Practices](#project-structure-best-practices)
- [Troubleshooting Common Issues](#troubleshooting-common-issues)

---

## Prerequisites

Before installing Terraform, ensure you have:

- A terminal/shell (bash, zsh, or PowerShell)
- Administrator/sudo access on your machine
- An AWS account (free tier is sufficient for learning)
- Git installed for version control

---

## Installation on Linux

### Method 1: APT Repository (Debian/Ubuntu)

```bash
# Install dependencies
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common

# Add the HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor | \
  sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

# Verify the key fingerprint
gpg --no-default-keyring \
  --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
  --fingerprint

# Add the HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install Terraform
sudo apt-get update && sudo apt-get install terraform
```

### Method 2: YUM Repository (RHEL/CentOS/Fedora)

```bash
# Add HashiCorp repository
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

# Install Terraform
sudo yum -y install terraform
```

### Method 3: Manual Binary Installation

```bash
# Download the latest release (check https://releases.hashicorp.com/terraform/)
TERRAFORM_VERSION="1.7.3"
wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"

# Unzip and move to PATH
unzip "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
sudo mv terraform /usr/local/bin/
rm "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"

# Verify
terraform version
```

---

## Installation on macOS

### Method 1: Homebrew (Recommended)

```bash
# Install the HashiCorp tap
brew tap hashicorp/tap

# Install Terraform
brew install hashicorp/tap/terraform

# Upgrade later with
brew upgrade hashicorp/tap/terraform
```

### Method 2: Manual Binary Installation

```bash
# For Apple Silicon (M1/M2/M3)
TERRAFORM_VERSION="1.7.3"
curl -LO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_darwin_arm64.zip"
unzip "terraform_${TERRAFORM_VERSION}_darwin_arm64.zip"
sudo mv terraform /usr/local/bin/

# For Intel Macs, replace darwin_arm64 with darwin_amd64
```

---

## Installation on Windows

### Method 1: Chocolatey

```powershell
choco install terraform
```

### Method 2: Scoop

```powershell
scoop install terraform
```

### Method 3: Manual Installation

1. Download the Windows AMD64 zip from [releases.hashicorp.com/terraform](https://releases.hashicorp.com/terraform/).
2. Extract `terraform.exe` from the zip file.
3. Move `terraform.exe` to a directory in your PATH (e.g., `C:\tools\terraform\`).
4. Add the directory to your system PATH environment variable:
   - Open System Properties > Advanced > Environment Variables
   - Under System Variables, find `Path`, click Edit
   - Add the directory containing `terraform.exe`
5. Open a new PowerShell or Command Prompt and verify: `terraform version`

### Method 4: Windows Subsystem for Linux (WSL)

If you use WSL, follow the Linux installation instructions within your WSL distribution. This is the recommended approach for Windows users who want a Linux-like development experience.

---

## Using tfenv for Version Management

`tfenv` is a Terraform version manager that allows you to install and switch between multiple Terraform versions. This is essential when working on projects that require different Terraform versions.

### Install tfenv

```bash
# macOS
brew install tfenv

# Linux - clone the repository
git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv

# Add to PATH (bash)
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Add to PATH (zsh)
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Common tfenv Commands

```bash
# List available versions for installation
tfenv list-remote

# Install a specific version
tfenv install 1.7.3

# Install the latest version
tfenv install latest

# List locally installed versions
tfenv list

# Switch to a specific version
tfenv use 1.7.3

# Set a default version
tfenv use latest
```

### Pin Terraform Version per Project

Create a `.terraform-version` file in your project root:

```bash
echo "1.7.3" > .terraform-version
```

When you `cd` into the project directory and run `terraform`, tfenv automatically uses the pinned version. This ensures every team member uses the same Terraform version.

### tenv: An Alternative Version Manager

`tenv` is a newer version manager written in Go that supports Terraform, OpenTofu, and Terragrunt:

```bash
# macOS
brew install tenv

# Usage is similar to tfenv
tenv tf install 1.7.3
tenv tf use 1.7.3
```

---

## IDE Setup

### Visual Studio Code (Recommended)

#### Essential Extensions

1. **HashiCorp Terraform** (`hashicorp.terraform`)
   - Official extension from HashiCorp
   - Syntax highlighting, IntelliSense, code navigation
   - Terraform Language Server integration
   - Install: `code --install-extension hashicorp.terraform`

2. **Terraform doc snippets** (`run-at-scale.terraform-doc-snippets`)
   - Code snippets for common AWS resources
   - Speeds up writing Terraform configurations

#### Recommended VS Code Settings

Add these to your `.vscode/settings.json`:

```json
{
  "[terraform]": {
    "editor.defaultFormatter": "hashicorp.terraform",
    "editor.formatOnSave": true,
    "editor.formatOnSaveMode": "file"
  },
  "[terraform-vars]": {
    "editor.defaultFormatter": "hashicorp.terraform",
    "editor.formatOnSave": true,
    "editor.formatOnSaveMode": "file"
  },
  "terraform.experimentalFeatures.validateOnSave": true,
  "terraform.experimentalFeatures.prefillRequiredFields": true,
  "editor.semanticHighlighting.enabled": true
}
```

### JetBrains IDEs (IntelliJ, GoLand, PyCharm)

Install the **Terraform and HCL** plugin from the JetBrains marketplace. It provides syntax highlighting, code completion, and navigation for Terraform files.

### Neovim

For Neovim users, use `nvim-lspconfig` with the Terraform Language Server:

```lua
-- In your LSP configuration
require('lspconfig').terraformls.setup{}

-- Install terraform-ls
-- brew install hashicorp/tap/terraform-ls
```

Additionally, install `tree-sitter-hcl` for enhanced syntax highlighting:

```lua
require('nvim-treesitter.configs').setup {
  ensure_installed = { "terraform", "hcl" },
}
```

---

## AWS CLI and Credentials Setup

Terraform uses the AWS SDK to interact with AWS. You need the AWS CLI configured with valid credentials.

### Install AWS CLI v2

```bash
# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# macOS
brew install awscli

# Windows
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi
```

### Configure AWS Credentials

```bash
aws configure
# AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
# AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
# Default region name [None]: us-east-1
# Default output format [None]: json
```

This creates two files:

- `~/.aws/credentials` - Contains your access keys
- `~/.aws/config` - Contains your region and output preferences

### Using Named Profiles

For multiple AWS accounts, use named profiles:

```bash
aws configure --profile dev
aws configure --profile staging
aws configure --profile production
```

In Terraform, reference a profile:

```hcl
provider "aws" {
  region  = "us-east-1"
  profile = "dev"
}
```

### Using Environment Variables

```bash
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
export AWS_DEFAULT_REGION="us-east-1"
```

### Authentication Priority Order

Terraform (via the AWS SDK) checks credentials in this order:

1. Environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
2. Shared credentials file (`~/.aws/credentials`)
3. Shared config file (`~/.aws/config`)
4. EC2 Instance Metadata / ECS Task Role
5. SSO credentials

For production use, prefer IAM roles (instance profiles, OIDC federation) over static access keys.

---

## Verify Installation

Run these commands to confirm everything is working:

```bash
# Check Terraform version
terraform version
# Terraform v1.7.3
# on linux_amd64

# Check available commands
terraform -help

# Verify AWS CLI
aws --version
# aws-cli/2.15.10 Python/3.11.6 Linux/6.5.0

# Verify AWS identity
aws sts get-caller-identity
# {
#     "UserId": "AIDAIOSFODNN7EXAMPLE",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/terraform-user"
# }
```

### Enable Tab Completion

```bash
# Bash
terraform -install-autocomplete
# This adds a line to ~/.bashrc

# Zsh
terraform -install-autocomplete
# This adds a line to ~/.zshrc

# Reload your shell
source ~/.bashrc  # or source ~/.zshrc
```

---

## First Project Walkthrough

Create a simple project that provisions an S3 bucket to verify your entire setup works end to end.

### Step 1: Create the Project Directory

```bash
mkdir -p ~/terraform-first-project && cd ~/terraform-first-project
```

### Step 2: Write the Configuration

Create a file named `main.tf`:

```hcl
terraform {
  required_version = ">= 1.5.0"

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

resource "aws_s3_bucket" "first_bucket" {
  bucket = "my-first-terraform-bucket-${random_id.suffix.hex}"

  tags = {
    Name        = "My First Terraform Bucket"
    Environment = "learning"
    ManagedBy   = "terraform"
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.first_bucket.bucket
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.first_bucket.arn
}
```

### Step 3: Initialize

```bash
terraform init
```

This downloads the AWS provider and the random provider, and sets up the working directory.

### Step 4: Format and Validate

```bash
# Auto-format your code
terraform fmt

# Validate the syntax
terraform validate
# Success! The configuration is valid.
```

### Step 5: Plan

```bash
terraform plan
```

Review the output. It should show two resources to create: the random ID and the S3 bucket.

### Step 6: Apply

```bash
terraform apply
```

Type `yes` when prompted. Terraform creates the resources and outputs the bucket name and ARN.

### Step 7: Verify

```bash
# Check the bucket exists
aws s3 ls | grep terraform-bucket

# View the Terraform state
terraform show
```

### Step 8: Clean Up

```bash
terraform destroy
```

Type `yes` to destroy all resources. Always clean up learning resources to avoid unexpected AWS charges.

---

## Project Structure Best Practices

### Simple Project

```
project/
  main.tf           # Primary resources
  variables.tf      # Input variable declarations
  outputs.tf        # Output value declarations
  terraform.tfvars  # Variable values (do not commit secrets)
  providers.tf      # Provider configuration
  versions.tf       # Terraform and provider version constraints
  .gitignore        # Ignore .terraform/, *.tfstate, etc.
```

### Recommended .gitignore

```gitignore
# Local .terraform directories
**/.terraform/*

# .tfstate files
*.tfstate
*.tfstate.*

# Crash log files
crash.log
crash.*.log

# Exclude .tfvars files that might contain sensitive data
*.tfvars
*.tfvars.json

# Ignore override files
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Ignore CLI configuration files
.terraformrc
terraform.rc

# Ignore lock file for module development (keep it for root modules)
# .terraform.lock.hcl
```

### Lock File

The `.terraform.lock.hcl` file records the exact provider versions and hashes used. Always commit this file to version control for root modules to ensure reproducible builds across team members and CI/CD pipelines.

---

## Troubleshooting Common Issues

### "Error: No valid credential sources found"

Terraform cannot find AWS credentials. Verify:

```bash
aws sts get-caller-identity
```

If this fails, reconfigure your credentials with `aws configure`.

### "Error: Failed to query available provider packages"

Network issue or incorrect provider source. Check:

- Internet connectivity
- Provider source spelling in `required_providers`
- Corporate proxy settings (set `HTTPS_PROXY` environment variable)

### "Error: Unsupported Terraform Core version"

Your Terraform version does not meet the `required_version` constraint. Use tfenv to install the correct version:

```bash
tfenv install 1.7.3
tfenv use 1.7.3
```

### "Error: Failed to load plugin schemas"

Corrupted provider cache. Clear and reinitialize:

```bash
rm -rf .terraform
rm .terraform.lock.hcl
terraform init
```

### State Lock Errors

If a previous operation was interrupted, the state may be locked:

```bash
# Only use this if you are certain no other operation is running
terraform force-unlock LOCK_ID
```

### Permission Denied on Linux/macOS

If `terraform` is not executable:

```bash
chmod +x /usr/local/bin/terraform
```

---

## Next Steps

With Terraform installed and verified, continue to:

- [HCL Syntax](hcl-syntax.md) to learn the configuration language
- [Terraform CLI Commands](terraform-cli-commands.md) to explore all available commands
- [State Management](state-management.md) to understand how Terraform tracks resources
