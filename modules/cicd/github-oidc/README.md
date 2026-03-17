# GitHub OIDC Module

Terraform module to configure GitHub Actions OIDC authentication with AWS, enabling keyless access to AWS resources from GitHub workflows.

## Features

- GitHub OIDC identity provider creation (or use existing)
- IAM role with trust policy for specific repositories and branches
- Support for branch, environment, tag, and pull request subject claims
- Managed and inline policy attachments
- Permissions boundary support
- Configurable thumbprint list
- Multi-repository support
- Consistent naming and tagging

## Usage

```hcl
module "github_oidc" {
  source = "../../modules/cicd/github-oidc"

  project     = "myapp"
  environment = "prod"

  github_repositories = [
    {
      owner        = "myorg"
      name         = "myapp"
      branches     = ["main", "release/*"]
      environments = ["production"]
    }
  ]

  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonECR_FullAccess",
  ]

  inline_policies = {
    deploy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = ["ecs:UpdateService"]
        Resource = "*"
      }]
    })
  }
}
```

### GitHub Actions Workflow

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::123456789012:role/myapp-prod-github-actions
      aws-region: us-east-1
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project | Project name | string | - | yes |
| environment | Environment name | string | - | yes |
| github_repositories | Trusted repository configs | list(object) | - | yes |
| create_oidc_provider | Create OIDC provider | bool | true | no |
| policy_arns | Managed policy ARNs | list(string) | [] | no |
| inline_policies | Inline policy JSON map | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| oidc_provider_arn | OIDC provider ARN |
| role_arn | IAM role ARN |
| role_name | IAM role name |
