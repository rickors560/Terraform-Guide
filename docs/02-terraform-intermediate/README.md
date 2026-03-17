# 02 - Terraform Intermediate

This section builds on the basics and introduces the features that make Terraform powerful for real-world infrastructure: variables for flexibility, modules for reuse, data sources for referencing existing resources, and workspaces for environment separation.

## Prerequisites

- Complete [01 - Terraform Basics](../01-terraform-basics/) or equivalent experience.
- Comfortable with HCL syntax, CLI commands, and state concepts.

## Learning Objectives

After completing this section, you will be able to:

- Define and use input variables with types, defaults, and validation
- Create outputs to expose values from your configurations
- Use data sources to query existing AWS resources
- Build and consume reusable Terraform modules
- Use built-in functions and expressions (string, collection, numeric, type conversions)
- Manage multiple environments with Terraform workspaces
- Understand provisioners and when (not) to use them
- Evaluate Terraform Cloud for remote execution and collaboration

## Documents

| # | File | Description | Est. Reading Time |
|---|------|-------------|-------------------|
| 1 | [variables-and-outputs.md](./variables-and-outputs.md) | Input variables (types, defaults, validation, sensitive), output values, variable precedence, `.tfvars` files, and environment variables. | 15 min |
| 2 | [data-sources.md](./data-sources.md) | Querying existing resources, AMI lookups, availability zones, remote state data, and combining data sources with resources. | 10 min |
| 3 | [modules.md](./modules.md) | Module structure, source types (local, registry, Git), input/output contracts, module composition, and versioning strategies. | 20 min |
| 4 | [functions-and-expressions.md](./functions-and-expressions.md) | Built-in functions (string, numeric, collection, encoding, filesystem, type), conditional expressions, for expressions, dynamic blocks, and splat expressions. | 15 min |
| 5 | [workspaces.md](./workspaces.md) | CLI workspaces vs. Terraform Cloud workspaces, when to use each, workspace-based environment separation, and alternative patterns. | 10 min |
| 6 | [provisioners.md](./provisioners.md) | `local-exec`, `remote-exec`, `file` provisioners, `null_resource`, why provisioners are a last resort, and alternatives (user_data, cloud-init, Ansible). | 10 min |
| 7 | [terraform-cloud.md](./terraform-cloud.md) | Terraform Cloud features, remote execution, VCS integration, policy as code (Sentinel), cost estimation, and private module registry. | 15 min |

**Total estimated reading time: ~95 minutes**

## Suggested Reading Order

Read in the order listed above. The key progression is:

1. Variables and outputs -- the foundation of parameterized configs
2. Data sources -- connecting to existing infrastructure
3. Modules -- the most important concept for code reuse
4. Functions -- making your configurations dynamic
5. Workspaces, provisioners, and Terraform Cloud -- operational patterns

## Hands-On Practice

After completing this section, you will understand how the `modules/` directory is structured:

- **Study module structure:** Look at any module in `modules/` (e.g., `modules/networking/vpc/`) to see variables, outputs, and locals in action.
- **Deploy a component:** `components/security-groups/` demonstrates how components pass variables to modules.
- **Try data sources:** `components/eks/data.tf` shows remote state data sources referencing VPC outputs.

## What's Next

Continue to [03 - Terraform Advanced](../03-terraform-advanced/) for testing, importing existing infrastructure, and performance optimization.
