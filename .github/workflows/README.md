# GitHub Actions Workflows

CI/CD automation for the Terraform infrastructure and MyApp application. Workflows handle pull request validation, Terraform plan/apply, application build/deploy to EKS, security scanning, and drift detection.

## Workflows

### 1. Terraform Plan (`terraform-plan.yml`)

**Trigger**: Pull requests to `main` that modify `*.tf`, `*.tfvars`, `modules/**`, `environments/**`, or `components/**` files.

**Jobs**:

| Job | Description |
|---|---|
| `fmt-check` | Runs `terraform fmt -check -recursive` and posts a PR comment if formatting fails |
| `validate` (matrix: dev, staging, prod) | Runs `terraform init -backend=false` and `terraform validate` per environment |
| `tflint` | Runs TFLint static analysis on all modules and environments |
| `checkov` | Runs Checkov IaC security scan, uploads SARIF to GitHub Security tab |
| `plan` (matrix: dev, staging, prod) | Authenticates via OIDC, runs `terraform plan`, posts plan output as a PR comment, uploads plan artifact |
| `infracost` | Generates cost estimation comparing the PR branch to the base branch, posts cost diff as a PR comment |

**Key features**: Concurrency group per PR number (cancels in-progress runs), Terraform plugin caching, plan output truncated to 60KB for PR comments.

---

### 2. Terraform Apply (`terraform-apply.yml`)

**Trigger**: Pushes/merges to `main` that modify `*.tf`, `*.tfvars`, `modules/**`, `environments/**`, or `components/**` files.

**Jobs**:

| Job | Description |
|---|---|
| `deploy-dev` | Automatic: plan + apply to dev environment |
| `deploy-staging` | Automatic (after dev succeeds): plan + apply to staging |
| `deploy-prod` | Manual approval required: plan + apply to production |

**Key features**: Sequential deployment (dev -> staging -> prod), DynamoDB state lock verification before apply, `detailed-exitcode` to skip apply when no changes detected, Slack notifications on success/failure for each environment.

---

### 3. PR Checks (`pr-checks.yml`)

**Trigger**: Pull requests to `main` that modify `application/**` files.

**Jobs**:

| Job | Description |
|---|---|
| `changes` | Detects which paths changed (backend vs frontend) using path filters |
| `backend-lint` | Java compilation and optional Checkstyle check |
| `backend-unit-tests` | Maven unit tests with test report publishing |
| `backend-integration-tests` | Maven integration tests (after unit tests pass) |
| `frontend-lint` | ESLint and TypeScript type checking |
| `frontend-unit-tests` | Jest tests with coverage report upload |
| `frontend-build` | Production build with bundle size warning (>5MB threshold) |
| `docker-build-backend` | Docker image build test (no push) |
| `docker-build-frontend` | Docker image build test (no push) |
| `pr-checks-passed` | Summary gate: aggregates all job results |

**Key features**: Path-based conditional execution (backend jobs skip when only frontend changed and vice versa), concurrency group per PR number, test result publishing via dorny/test-reporter.

---

### 4. Application Build & Deploy (`app-build-deploy.yml`)

**Trigger**: Pushes to `main` that modify `application/**` files.

**Jobs**:

| Job | Description |
|---|---|
| `build-backend` | Maven test + package, Docker build + push to ECR |
| `build-frontend` | npm lint + test + build, Docker build + push to ECR |
| `deploy` | Configure kubectl for EKS, record current images (for rollback), `kubectl set image` for both deployments, wait for rollout |
| `smoke-test` | Health check retries, API response check, pod status verification |
| `rollback` | Triggered on failure: `kubectl rollout undo` for both deployments, Slack alert |

**Key features**: Image tags include short SHA + timestamp, OCI labels on Docker images, automatic rollback if smoke tests fail, Slack notifications for deploy success and rollback.

---

### 5. Security Scan (`security-scan.yml`)

**Trigger**: Weekly cron (Mondays at 05:00 UTC), pull requests to `main`, and manual dispatch.

**Jobs**:

| Job | Description |
|---|---|
| `trivy` | Filesystem scan for vulnerabilities (CRITICAL/HIGH), IaC config scan (CRITICAL/HIGH/MEDIUM), Dockerfile scans for backend and frontend |
| `checkov` | Terraform IaC scan, Kubernetes manifest scan, Dockerfile scan (with SARIF uploads) |
| `tfsec` | Terraform security analysis on modules, environments, and components |
| `dependency-review` | PR-only: reviews dependency changes, fails on HIGH severity or GPL-3.0/AGPL-3.0 licenses |
| `security-summary` | Aggregates results into a GitHub Actions step summary table |

**Key features**: All SARIF results uploaded to GitHub Security tab, soft-fail mode (reports issues without blocking), multiple scanning frameworks for defense in depth.

---

### 6. Terraform Drift Detection (`terraform-drift.yml`)

**Trigger**: Daily cron at 06:00 UTC, manual dispatch (with optional single-environment selection).

**Jobs**:

| Job | Description |
|---|---|
| `drift-detect` (matrix: dev, staging, prod) | Runs `terraform plan -detailed-exitcode` in detect-only mode, generates drift report |
| `drift-summary` | Downloads all drift reports, generates a combined summary table |

**Key features**: Uses exit code 2 to detect drift without applying, drift reports uploaded as artifacts (30-day retention), Slack alert per environment on drift, email alert via SMTP, manual trigger supports selecting a single environment.

## How Workflows Interact

```
Pull Request opened (*.tf files)
  --> terraform-plan.yml
      - fmt, validate, tflint, checkov
      - plan for all environments (posted as PR comments)
      - infracost diff (posted as PR comment)

Pull Request opened (application/** files)
  --> pr-checks.yml
      - backend lint, tests, docker build
      - frontend lint, tests, build, docker build

Pull Request opened (any files)
  --> security-scan.yml
      - trivy, checkov, tfsec, dependency review

Merge to main (*.tf files)
  --> terraform-apply.yml
      - apply dev (auto)
      - apply staging (auto, after dev)
      - apply prod (manual approval)

Merge to main (application/** files)
  --> app-build-deploy.yml
      - build + push images to ECR
      - deploy to EKS
      - smoke test
      - rollback on failure

Daily at 06:00 UTC
  --> terraform-drift.yml
      - detect drift in all environments
      - alert on drift (Slack + email)

Weekly on Monday 05:00 UTC
  --> security-scan.yml
      - full security scan
```

## Required GitHub Secrets

| Secret | Used By | Description |
|---|---|---|
| `AWS_ROLE_ARN_DEV` | terraform-plan, terraform-apply, app-build-deploy | OIDC role ARN for dev AWS account |
| `AWS_ROLE_ARN_STAGING` | terraform-plan, terraform-apply | OIDC role ARN for staging AWS account |
| `AWS_ROLE_ARN_PROD` | terraform-plan, terraform-apply | OIDC role ARN for prod AWS account |
| `INFRACOST_API_KEY` | terraform-plan | Infracost API key for cost estimation |
| `SLACK_WEBHOOK_URL` | terraform-apply, app-build-deploy, terraform-drift | Slack incoming webhook for notifications |
| `SMTP_SERVER` | terraform-drift | SMTP server address for email alerts |
| `SMTP_PORT` | terraform-drift | SMTP server port |
| `SMTP_USERNAME` | terraform-drift | SMTP authentication username |
| `SMTP_PASSWORD` | terraform-drift | SMTP authentication password |
| `ALERT_EMAIL_RECIPIENTS` | terraform-drift | Comma-separated email addresses for drift alerts |

`GITHUB_TOKEN` is automatically provided by GitHub Actions and used for PR comments, SARIF uploads, and TFLint plugin downloads.

## Required GitHub Environments

| Environment | Protection Rules | Used By |
|---|---|---|
| `dev` | None (auto-deploy) | terraform-apply, app-build-deploy |
| `staging` | None (auto-deploy after dev) | terraform-apply |
| `prod` | **Required reviewers** (manual approval) | terraform-apply |

## OIDC Setup for AWS

All workflows authenticate to AWS using OIDC (OpenID Connect) via `aws-actions/configure-aws-credentials@v4` with `role-to-assume`. This eliminates the need for long-lived AWS access keys.

To set this up:

1. Create an IAM OIDC identity provider in each AWS account for `token.actions.githubusercontent.com`
2. Create IAM roles with trust policies that allow the GitHub OIDC provider for your specific repository and branches
3. Store the role ARNs as GitHub secrets (`AWS_ROLE_ARN_DEV`, `AWS_ROLE_ARN_STAGING`, `AWS_ROLE_ARN_PROD`)
4. Workflows request `permissions: id-token: write` to obtain the OIDC token

Each workflow uses a unique `role-session-name` (including environment name and run ID) for CloudTrail auditability.
