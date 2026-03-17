provider "aws" {
  region = var.aws_region
}

module "s3" {
  source = "../../"

  project            = var.project
  environment        = var.environment
  bucket_name_suffix = "assets"

  enable_versioning = true
  sse_algorithm     = "AES256"

  lifecycle_rules = [
    {
      id = "archive-old-objects"
      transitions = [
        { days = 90, storage_class = "STANDARD_IA" },
        { days = 180, storage_class = "GLACIER" },
      ]
      expiration_days                    = 365
      noncurrent_version_expiration_days = 90
    }
  ]

  cors_rules = [
    {
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["https://example.com"]
      allowed_headers = ["*"]
      max_age_seconds = 3600
    }
  ]

  team        = var.team
  cost_center = var.cost_center
  repository  = var.repository
}
