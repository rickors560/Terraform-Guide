provider "aws" {
  region = var.aws_region
}

module "ebs" {
  source = "../../"

  project            = var.project
  environment        = var.environment
  volume_name_suffix = "data"

  availability_zone = "${var.aws_region}a"
  type              = "gp3"
  size              = 100
  iops              = 3000
  throughput        = 125
  encrypted         = true

  team        = var.team
  cost_center = var.cost_center
  repository  = var.repository
}
