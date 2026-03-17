# CloudFront Component

Production-grade CloudFront distribution with S3 origin using Origin Access Control (OAC), cache policies, custom error pages, and standard logging.

## Features

- S3 origin with Origin Access Control (OAC) - modern replacement for OAI
- HTTP/2 and HTTP/3 support
- Managed CachingOptimized policy (or custom cache policy)
- Managed CORS-S3Origin request policy
- Managed SecurityHeadersPolicy for response headers
- Custom error responses for 403, 404, and 500
- Standard logging to S3
- Origin Shield support for reduced origin load
- Geo-restriction support
- Custom domain aliases with ACM certificate

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply

# Upload content to the origin bucket
aws s3 cp ./site/ s3://$(terraform output -raw origin_bucket_id)/ --recursive

# Access via CloudFront
curl https://$(terraform output -raw distribution_domain_name)/
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `default_root_object` | Default root object | `string` | `index.html` |
| `price_class` | Price class | `string` | `PriceClass_200` |
| `domain_aliases` | Custom domains | `list(string)` | `[]` |
| `acm_certificate_arn` | ACM cert (us-east-1) | `string` | `""` |

## Outputs

| Name | Description |
|------|-------------|
| `distribution_domain_name` | CloudFront domain |
| `distribution_id` | Distribution ID |
| `origin_bucket_id` | S3 origin bucket |
