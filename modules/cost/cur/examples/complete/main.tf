provider "aws" {
  region = "us-east-1"
}

module "cur" {
  source = "../../"

  project     = var.project
  environment = var.environment

  report_name                = "detailed-report"
  time_unit                  = "DAILY"
  format                     = "Parquet"
  compression                = "Parquet"
  additional_schema_elements = ["RESOURCES"]
  additional_artifacts       = ["ATHENA"]
  report_versioning          = "OVERWRITE_REPORT"
  refresh_closed_reports     = true
  s3_prefix                  = "cur-reports"

  additional_tags = {
    Example = "complete"
  }
}
