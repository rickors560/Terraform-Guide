# CloudFront Module

Production-grade AWS CloudFront distribution module with S3 OAC, custom origins, caching, and WAF integration.

## Features

- S3 origin with Origin Access Control (OAC)
- Custom origin support with configurable headers
- Custom domain names with ACM certificate
- Ordered cache behaviors for path-based routing
- Cache policy, origin request policy, and response headers policy support
- Custom error responses
- WAF Web ACL association
- Geo restrictions
- Logging configuration
- Price class selection

## Usage

```hcl
module "cloudfront" {
  source = "../../modules/networking/cloudfront"

  project     = "myapp"
  environment = "prod"

  aliases             = ["cdn.example.com"]
  acm_certificate_arn = module.acm.certificate_arn

  s3_origin = {
    enabled                = true
    bucket_regional_domain = module.s3.bucket_regional_domain_name
    origin_id              = "s3-assets"
  }

  default_cache_behavior = {
    target_origin_id = "s3-assets"
  }

  price_class = "PriceClass_100"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project | Project name | string | - | yes |
| environment | Environment name | string | - | yes |
| default_cache_behavior | Default cache behavior | object | - | yes |
| s3_origin | S3 origin config | object | disabled | no |
| custom_origins | Custom origins | list(object) | [] | no |
| aliases | Custom domain names | list(string) | [] | no |
| acm_certificate_arn | ACM cert ARN | string | null | no |

## Outputs

| Name | Description |
|------|-------------|
| distribution_id | Distribution ID |
| distribution_domain_name | Distribution domain name |
| distribution_hosted_zone_id | Hosted zone ID for alias records |
