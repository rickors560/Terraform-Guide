## Description

<!-- Provide a brief summary of the changes and the motivation behind them. -->



## Type of Change

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Infrastructure change (Terraform modules, environments, or components)
- [ ] Configuration change (CI/CD, Kubernetes manifests, Helm charts)
- [ ] Documentation update
- [ ] Refactoring (no functional changes)
- [ ] Dependency update

## Checklist

- [ ] I have performed a self-review of my code
- [ ] I have added tests that prove my fix is effective or my feature works
- [ ] New and existing unit tests pass locally
- [ ] I have updated the documentation accordingly
- [ ] My changes generate no new warnings or errors
- [ ] I have checked for breaking changes and documented them above
- [ ] Any dependent changes have been merged and published

### Infrastructure Changes (if applicable)

- [ ] `terraform fmt` passes
- [ ] `terraform validate` passes
- [ ] Security scan (Checkov/tfsec) shows no new critical findings
- [ ] Cost estimate has been reviewed
- [ ] State migration plan documented (if applicable)

## Terraform Plan Output

<!-- The CI pipeline will post the plan output as a PR comment automatically.
     If running manually, paste the relevant plan output below. -->

<details>
<summary>Show Terraform Plan</summary>

```hcl
# Paste terraform plan output here if running manually
```

</details>

## Cost Estimate

<!-- Infracost will post the cost estimate as a PR comment automatically.
     If running manually, paste the summary below. -->

<details>
<summary>Show Cost Estimate</summary>

```
# Paste infracost output here if running manually
```

</details>

## Screenshots (if applicable)

<!-- Add screenshots to help explain your changes. -->

## Additional Notes

<!-- Any additional information reviewers should know. -->
