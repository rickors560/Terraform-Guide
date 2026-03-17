# Route53 Component

Production-grade Route53 hosted zone with A, CNAME, MX, TXT, CAA records, alias records, health checks, and optional DNSSEC.

## Features

- Public hosted zone with configurable record types
- A records (standard and alias for ALB/CloudFront/S3)
- CNAME, MX, TXT, and CAA records
- Health check with CloudWatch alarm
- DNSSEC signing support
- Multi-region health check monitoring

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply

# Update your domain registrar with the NS records:
terraform output name_servers
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `domain_name` | Domain name | `string` | -- |
| `a_records` | A records map | `map(object)` | `{}` |
| `alias_records` | Alias A records | `map(object)` | `{}` |
| `cname_records` | CNAME records | `map(object)` | `{}` |
| `mx_records` | MX records | `list(string)` | `[]` |
| `txt_records` | TXT records | `map(object)` | `{}` |
| `health_check_fqdn` | Health check FQDN | `string` | `""` |

## Outputs

| Name | Description |
|------|-------------|
| `zone_id` | Hosted zone ID |
| `name_servers` | NS records for delegation |
| `health_check_id` | Health check ID |
