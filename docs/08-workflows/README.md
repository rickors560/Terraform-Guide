# 08 - Workflows

Day-to-day operational workflows for teams using this repository. This section provides practical guides for developers making infrastructure changes, new team members getting started, incident responders diagnosing infrastructure issues, and anyone writing operational runbooks.

## Prerequisites

- Complete [01 - Terraform Basics](../01-terraform-basics/) through [07 - Production Patterns](../07-production-patterns/), or equivalent experience.
- Access to the AWS accounts and Terraform state used by your team.
- Git, Terraform, and AWS CLI installed and configured.

## Learning Objectives

After completing this section, you will be able to:

- Follow the standard developer workflow for making infrastructure changes (branch, plan, review, apply)
- Onboard new team members with a clear checklist and orientation path
- Respond to infrastructure incidents using structured procedures
- Write operational runbooks that follow a consistent, actionable format

## Documents

| # | File | Description | Est. Reading Time |
|---|------|-------------|-------------------|
| 1 | [developer-workflow.md](./developer-workflow.md) | End-to-end workflow for infrastructure changes: branching strategy, writing Terraform code, running local plan, creating PRs, CI plan review, approval process, apply, and post-apply verification. | 15 min |
| 2 | [onboarding-guide.md](./onboarding-guide.md) | New team member checklist: AWS account access, tool installation, repository structure orientation, first deployment walkthrough, and documentation reading order. | 10 min |
| 3 | [incident-response.md](./incident-response.md) | Infrastructure incident procedures: detection, triage, diagnosis with Terraform state and AWS console, remediation (rollback, hotfix, manual intervention), post-mortem, and communication templates. | 15 min |
| 4 | [runbook-template.md](./runbook-template.md) | Template for writing operational runbooks: title, description, prerequisites, step-by-step procedure, verification, rollback, and related resources. Use this template for all new runbooks. | 5 min |

**Total estimated reading time: ~45 minutes**

## Suggested Reading Order

- **New to the team?** Start with `onboarding-guide.md`, then `developer-workflow.md`.
- **Making your first change?** Read `developer-workflow.md` step by step.
- **On-call or responding to an incident?** Go directly to `incident-response.md`.
- **Writing a new runbook?** Copy `runbook-template.md` as your starting point.

## Hands-On Practice

- **Developer workflow:** Make a small change to `components/s3/` (e.g., add a tag), follow the full workflow in `developer-workflow.md`, and deploy to `dev`.
- **Onboarding:** Use `onboarding-guide.md` as a checklist. Deploy `components/vpc/` and `components/ec2/` in `dev` as your first hands-on exercise.
- **Incident response:** Run `terraform plan` against a running component to practice drift detection. Simulate an incident by manually changing a resource in the AWS console and reconciling with Terraform.
- **Runbooks:** Copy `runbook-template.md` and write a runbook for a common task in your environment (e.g., rotating a database password, scaling an EKS node group).

## Related Resources

- **[05 - CI/CD](../05-cicd/)** -- How the automated pipeline fits into the developer workflow.
- **[07 - Production Patterns](../07-production-patterns/)** -- Multi-environment strategy, secrets management, and compliance context for operational decisions.
- **[environments/](../../environments/)** -- The environment configurations (`dev`, `staging`, `prod`) where changes are deployed.
- **[components/](../../components/)** -- The individual infrastructure components you will deploy and manage.
