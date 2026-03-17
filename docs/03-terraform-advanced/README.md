# 03 - Terraform Advanced

Advanced Terraform techniques for teams managing production infrastructure. This section covers testing, importing brownfield resources, safe refactoring, custom providers, dependency management, performance tuning, and security hardening.

## Prerequisites

- Complete [01 - Terraform Basics](../01-terraform-basics/) and [02 - Terraform Intermediate](../02-terraform-intermediate/).
- Experience writing and deploying Terraform configurations with modules.
- Familiarity with at least one CI/CD system is helpful for the testing content.

## Learning Objectives

After completing this section, you will be able to:

- Write and run unit tests, integration tests, and contract tests for Terraform modules
- Import existing AWS resources into Terraform state
- Refactor configurations safely using `moved` blocks
- Understand how custom Terraform providers work
- Manage complex dependency chains across modules and components
- Optimize Terraform performance for large configurations
- Apply security best practices for Terraform state, secrets, and provider configurations

## Documents

| # | File | Description | Est. Reading Time |
|---|------|-------------|-------------------|
| 1 | [testing.md](./testing.md) | Testing strategies: `terraform validate`, `terraform plan` assertions, `terraform test` (native), Terratest (Go), checkov, tflint, and test organization patterns. | 20 min |
| 2 | [import-existing.md](./import-existing.md) | Importing existing AWS resources with `terraform import` and `import` blocks. Generating config from state, handling drift, and bulk import strategies. | 15 min |
| 3 | [moved-blocks.md](./moved-blocks.md) | Refactoring safely with `moved` blocks: renaming resources, moving resources between modules, splitting and merging state files without destroying infrastructure. | 10 min |
| 4 | [custom-providers.md](./custom-providers.md) | How Terraform providers work internally, the provider protocol, when to write a custom provider, and the Terraform Plugin Framework. | 15 min |
| 5 | [dependency-management.md](./dependency-management.md) | Implicit vs. explicit dependencies, `depends_on`, cross-module dependencies, dependency inversion with data sources, and circular dependency resolution. | 15 min |
| 6 | [performance-optimization.md](./performance-optimization.md) | Speeding up Terraform: parallelism tuning, targeted applies, state splitting strategies, provider caching, and reducing API calls. | 10 min |
| 7 | [security-best-practices.md](./security-best-practices.md) | Securing Terraform: state encryption, secret management, least-privilege IAM for Terraform, provider credential handling, and policy-as-code with Sentinel/OPA. | 15 min |

**Total estimated reading time: ~100 minutes**

## Suggested Reading Order

These topics are relatively independent. Suggested priority:

1. **Testing** -- Start here; it applies to everything else you build.
2. **Import existing** and **moved blocks** -- Essential for real-world brownfield projects.
3. **Dependency management** -- Critical for large multi-module architectures.
4. **Security best practices** -- Read before deploying to production.
5. **Performance optimization** -- Read when your applies start taking too long.
6. **Custom providers** -- Reference material for advanced use cases.

## Hands-On Practice

- **Testing:** Run `terraform validate` and `terraform plan` against any module in `modules/` to practice validation workflows.
- **Import:** Try importing a manually created S3 bucket into the `components/s3/` state.
- **Moved blocks:** Study how `modules/containers/eks/` is split into sub-modules (cluster, node-group, addons, irsa) -- this is the kind of refactoring that `moved` blocks enable.
- **Dependencies:** Examine `components/eks/data.tf` and `components/alb/data.tf` for cross-component dependency patterns.

## What's Next

Continue to [04 - AWS Services Guide](../04-aws-services-guide/) for a deep dive into every AWS service managed in this repository, or jump to [05 - CI/CD](../05-cicd/) to automate your Terraform workflows.
