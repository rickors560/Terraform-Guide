# 01 - Terraform Basics

The foundation of everything in this repository. This section introduces Terraform from scratch -- what it is, how to install it, and how to write your first infrastructure-as-code configurations.

## Prerequisites

- None. This section assumes no prior Terraform experience.
- Basic command-line (terminal/shell) familiarity is helpful.
- An AWS account is needed to follow along with hands-on examples.

## Learning Objectives

After completing this section, you will be able to:

- Explain what Terraform is and how it differs from other IaC tools
- Install and configure Terraform on your machine
- Read and write HCL (HashiCorp Configuration Language) syntax
- Use core Terraform CLI commands (`init`, `plan`, `apply`, `destroy`)
- Configure AWS and other providers
- Understand how Terraform state works and why it matters
- Set up remote backends for team collaboration

## Documents

| # | File | Description | Est. Reading Time |
|---|------|-------------|-------------------|
| 1 | [what-is-terraform.md](./what-is-terraform.md) | Introduction to Infrastructure as Code and Terraform's role in the ecosystem. Compares Terraform to CloudFormation, Pulumi, and Ansible. | 10 min |
| 2 | [installation-setup.md](./installation-setup.md) | Step-by-step installation for macOS, Linux, and Windows. Configuring AWS credentials, editor plugins, and tfenv for version management. | 10 min |
| 3 | [hcl-syntax.md](./hcl-syntax.md) | HCL language fundamentals: blocks, arguments, expressions, types, strings, numbers, booleans, lists, maps, and comments. | 15 min |
| 4 | [terraform-cli-commands.md](./terraform-cli-commands.md) | Deep dive into CLI commands: `init`, `plan`, `apply`, `destroy`, `fmt`, `validate`, `show`, `output`, `state`, `taint`, `import`. | 15 min |
| 5 | [providers.md](./providers.md) | How providers work, configuring the AWS provider, provider versioning, multiple provider configurations, and provider aliases. | 10 min |
| 6 | [state-management.md](./state-management.md) | What Terraform state is, why it exists, the state file format, state locking, `terraform state` subcommands, and common pitfalls. | 15 min |
| 7 | [backends.md](./backends.md) | Remote backends with S3 and DynamoDB, backend configuration, state migration, partial backend configs, and backend best practices. | 10 min |

**Total estimated reading time: ~85 minutes**

## Suggested Reading Order

Read the files in the numbered order above. Each document builds on the previous one:

1. Understand the "why" -- `what-is-terraform.md`
2. Get set up -- `installation-setup.md`
3. Learn the language -- `hcl-syntax.md`
4. Learn the workflow -- `terraform-cli-commands.md`
5. Connect to AWS -- `providers.md`
6. Understand state -- `state-management.md`
7. Set up team collaboration -- `backends.md`

## Hands-On Practice

After completing this section, try deploying your first real infrastructure:

- **Module example:** `modules/networking/vpc/examples/complete/` -- A simple VPC deployment that uses the concepts from this section.
- **Component:** `components/vpc/` -- Deploy a full VPC with subnets, NAT gateways, and route tables.
- **Component:** `components/s3/` -- Deploy an S3 bucket (one of the simplest standalone components).

## What's Next

Continue to [02 - Terraform Intermediate](../02-terraform-intermediate/) to learn about variables, outputs, modules, and data sources.
