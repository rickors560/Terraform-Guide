# WAF Component

This component creates an AWS WAF v2 Web ACL with IP-based blocking/allowing, rate limiting with custom 429 responses, AWS managed rule groups (Common, Known Bad Inputs, SQLi, IP Reputation), optional geo-restriction, CloudWatch logging with redacted sensitive headers, and ALB association.

## Architecture

- **IP Sets**: Blocked and allowed IP sets for explicit control
- **Rate Limiting**: Configurable per-IP rate limit with custom JSON 429 response
- **Managed Rules**: AWS Common Rules, Known Bad Inputs, SQLi, IP Reputation
- **Geo-Restriction**: Optional country-level blocking
- **Logging**: CloudWatch Logs with filtered blocked/counted requests, redacted auth/cookie headers
- **Alarms**: CloudWatch alarms for blocked requests and rate limiting thresholds

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Inputs

| Name                       | Description                            | Type         | Default   |
|----------------------------|----------------------------------------|--------------|-----------|
| project_name               | Project name for naming                | string       | n/a       |
| environment                | Environment name                       | string       | n/a       |
| waf_scope                  | REGIONAL or CLOUDFRONT                 | string       | REGIONAL  |
| rate_limit                 | Requests per IP per 5 min              | number       | 2000      |
| blocked_ip_addresses       | IPs to block                           | list(string) | []        |
| blocked_country_codes      | Country codes to block                 | list(string) | []        |
| alb_arn                    | ALB ARN to associate                   | string       | ""        |

## Outputs

| Name          | Description              |
|---------------|--------------------------|
| web_acl_arn   | ARN of the WAF Web ACL   |
| web_acl_id    | ID of the WAF Web ACL    |
| log_group_arn | ARN of the WAF log group |
