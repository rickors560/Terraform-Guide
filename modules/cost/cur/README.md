# Cost and Usage Report (CUR) Module

Terraform module to create and manage AWS Cost and Usage Reports with S3 bucket storage.

## Features

- Cost and Usage Report with configurable granularity
- Auto-created S3 bucket with bucket policy for CUR service
- Multiple formats: CSV and Parquet
- Compression options: GZIP, ZIP, Parquet
- Additional schema elements (RESOURCES, SPLIT_COST_ALLOCATION_DATA)
- Additional artifacts for Athena, Redshift, QuickSight
- Report versioning (overwrite or create new)
- Refresh closed reports option
- S3 lifecycle rules for cost optimization
- Consistent naming and tagging

## Usage

```hcl
module "cur" {
  source = "../../modules/cost/cur"

  project     = "myapp"
  environment = "prod"

  report_name                = "monthly-report"
  time_unit                  = "DAILY"
  format                     = "Parquet"
  compression                = "Parquet"
  additional_schema_elements = ["RESOURCES"]
  additional_artifacts       = ["ATHENA"]
  report_versioning          = "OVERWRITE_REPORT"
  refresh_closed_reports     = true
}
```

## Important Notes

- CUR reports can only be created in us-east-1. If your provider is in another region, you may need a separate provider configuration.
- Reports may take up to 24 hours to start appearing in the S3 bucket.

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
| report_name | Report name suffix | string | "cost-usage-report" | no |
| time_unit | Report granularity | string | "DAILY" | no |
| format | Report format | string | "Parquet" | no |
| compression | Compression type | string | "Parquet" | no |
| additional_schema_elements | Schema elements | list(string) | ["RESOURCES"] | no |
| additional_artifacts | Artifact types | list(string) | ["ATHENA"] | no |
| report_versioning | Versioning strategy | string | "OVERWRITE_REPORT" | no |
| refresh_closed_reports | Refresh closed reports | bool | true | no |

## Outputs

| Name | Description |
|------|-------------|
| report_name | Name of the CUR report |
| report_arn | ARN of the CUR report |
| s3_bucket_id | S3 bucket ID |
| s3_bucket_arn | S3 bucket ARN |
