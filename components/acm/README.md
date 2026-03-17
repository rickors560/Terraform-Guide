# ACM Component

Production-grade ACM certificate with DNS validation via Route53, Subject Alternative Names (SANs), and optional CloudFront certificate.

## Features

- ACM certificate with DNS validation
- Subject Alternative Names (SANs) including wildcards
- Automatic Route53 DNS validation record creation
- Certificate transparency logging enabled
- Optional us-east-1 certificate for CloudFront
- Create-before-destroy lifecycle for zero-downtime renewals

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

### With Route53 DNS Validation (recommended)
Set `route53_zone_id` to your hosted zone ID. Terraform will create the validation
records and wait for the certificate to be issued.

### Manual DNS Validation
Leave `route53_zone_id` empty. After `terraform apply`, retrieve the validation records:
```bash
terraform output domain_validation_options
```
Create these DNS records manually at your DNS provider.

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `domain_name` | Primary domain | `string` | -- |
| `subject_alternative_names` | SANs | `list(string)` | `[]` |
| `route53_zone_id` | Zone ID for auto-validation | `string` | `""` |
| `create_cloudfront_certificate` | Create us-east-1 cert | `bool` | `false` |

## Outputs

| Name | Description |
|------|-------------|
| `certificate_arn` | Regional certificate ARN |
| `validated_certificate_arn` | Validated certificate ARN |
| `cloudfront_certificate_arn` | CloudFront certificate ARN |
| `domain_validation_options` | DNS validation records |
