# Security Policy

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability in this repository — including but not limited to exposed secrets, insecure Terraform configurations, or misconfigured AWS resources — please report it responsibly.

### How to Report

1. **Do not open a public GitHub issue.** Security vulnerabilities must be reported privately.
2. **Email:** Send a detailed report to the repository maintainers using the email address listed in the repository's GitHub profile, or use GitHub's private vulnerability reporting feature (Security tab > "Report a vulnerability").
3. **Include the following information:**
   - Description of the vulnerability
   - Steps to reproduce
   - Affected files or configurations
   - Potential impact
   - Suggested fix (if any)

### What to Expect

- **Acknowledgment** within 48 hours of your report.
- **Assessment** within 7 days. We will evaluate the severity and determine the appropriate fix.
- **Resolution** within 30 days for critical issues. We will coordinate disclosure timing with you.
- **Credit** in the fix commit and release notes (unless you prefer to remain anonymous).

### Scope

The following are in scope:

- Terraform configurations that would create insecure AWS resources (e.g., public S3 buckets, overly permissive security groups, unencrypted databases)
- Hardcoded secrets, API keys, or credentials in any file
- Insecure default variable values
- Missing encryption at rest or in transit
- Kubernetes manifests with security misconfigurations (e.g., privileged containers, missing network policies)
- CI/CD pipeline vulnerabilities (e.g., secret exposure in logs)

The following are out of scope:

- Vulnerabilities in Terraform, AWS CLI, or other third-party tools themselves (report those to their respective maintainers)
- Issues in forked or modified versions of this repository
- Social engineering attacks

### Security Best Practices in This Repository

- All secrets are stored in AWS Secrets Manager, never in code
- All S3 buckets enforce encryption at rest (AES-256 or KMS)
- All S3 buckets block public access by default
- All RDS instances use encrypted storage and enforce SSL connections
- All EKS clusters use private endpoint access
- IAM policies follow the principle of least privilege
- Pre-commit hooks include `detect-secrets` and `checkov` for automated security scanning
- State files are stored in encrypted S3 with versioning and access logging

## Supported Versions

| Version | Supported |
|---|---|
| Latest on `main` | Yes |
| Previous releases | Best effort |

## Acknowledgments

We appreciate the security research community and will publicly acknowledge contributors who report valid vulnerabilities (with their permission).
