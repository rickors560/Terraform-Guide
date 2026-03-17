provider "aws" {
  region = var.aws_region
}

module "s3_policy" {
  source = "../../"

  project     = var.project
  environment = var.environment
  name        = "s3-access"
  description = "S3 bucket access policy for application"

  policy_statements = [
    {
      sid     = "S3ListBucket"
      actions = ["s3:ListBucket"]
      resources = [
        "arn:aws:s3:::${var.project}-${var.environment}-*",
      ]
    },
    {
      sid     = "S3ReadWriteObjects"
      actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
      resources = [
        "arn:aws:s3:::${var.project}-${var.environment}-*/*",
      ]
    },
    {
      sid     = "DenyUnencryptedUploads"
      effect  = "Deny"
      actions = ["s3:PutObject"]
      resources = [
        "arn:aws:s3:::${var.project}-${var.environment}-*/*",
      ]
      conditions = [
        {
          test     = "StringNotEquals"
          variable = "s3:x-amz-server-side-encryption"
          values   = ["aws:kms"]
        },
      ]
    },
  ]

  team        = var.team
  cost_center = var.cost_center
}
