###############################################################################
# Example 07 — Multi-Region DR: Route53 Failover
# Primary (ap-south-1) + Secondary (us-east-1) with RDS cross-region replica,
# S3 cross-region replication, ALB in each region, Route53 failover routing,
# health checks, and CloudWatch alarms.
###############################################################################

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

###############################################################################
# Providers — Two Regions
###############################################################################

provider "aws" {
  region = var.primary_region
  alias  = "primary"

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Region      = "primary"
    }
  }
}

provider "aws" {
  region = var.secondary_region
  alias  = "secondary"

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Region      = "secondary"
    }
  }
}

# Default provider (for Route53 which is global)
provider "aws" {
  region = var.primary_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

###############################################################################
# Data Sources
###############################################################################

data "aws_availability_zones" "primary" {
  provider = aws.primary
  state    = "available"
}

data "aws_availability_zones" "secondary" {
  provider = aws.secondary
  state    = "available"
}

data "aws_caller_identity" "current" {
  provider = aws.primary
}

data "aws_ami" "primary" {
  provider    = aws.primary
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "secondary" {
  provider    = aws.secondary
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

locals {
  primary_azs   = slice(data.aws_availability_zones.primary.names, 0, 2)
  secondary_azs = slice(data.aws_availability_zones.secondary.names, 0, 2)
  account_id    = data.aws_caller_identity.current.account_id
}

###############################################################################
# PRIMARY REGION — VPC
###############################################################################

resource "aws_vpc" "primary" {
  provider             = aws.primary
  cidr_block           = var.primary_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project_name}-primary-vpc" }
}

resource "aws_internet_gateway" "primary" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary.id
  tags     = { Name = "${var.project_name}-primary-igw" }
}

resource "aws_subnet" "primary_public" {
  provider                = aws.primary
  count                   = 2
  vpc_id                  = aws_vpc.primary.id
  cidr_block              = cidrsubnet(var.primary_vpc_cidr, 8, count.index)
  availability_zone       = local.primary_azs[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project_name}-primary-public-${local.primary_azs[count.index]}" }
}

resource "aws_subnet" "primary_private" {
  provider          = aws.primary
  count             = 2
  vpc_id            = aws_vpc.primary.id
  cidr_block        = cidrsubnet(var.primary_vpc_cidr, 8, count.index + 10)
  availability_zone = local.primary_azs[count.index]
  tags              = { Name = "${var.project_name}-primary-private-${local.primary_azs[count.index]}" }
}

resource "aws_subnet" "primary_database" {
  provider          = aws.primary
  count             = 2
  vpc_id            = aws_vpc.primary.id
  cidr_block        = cidrsubnet(var.primary_vpc_cidr, 8, count.index + 20)
  availability_zone = local.primary_azs[count.index]
  tags              = { Name = "${var.project_name}-primary-database-${local.primary_azs[count.index]}" }
}

resource "aws_eip" "primary_nat" {
  provider = aws.primary
  domain   = "vpc"
  tags     = { Name = "${var.project_name}-primary-nat-eip" }
}

resource "aws_nat_gateway" "primary" {
  provider      = aws.primary
  allocation_id = aws_eip.primary_nat.id
  subnet_id     = aws_subnet.primary_public[0].id
  tags          = { Name = "${var.project_name}-primary-nat" }
  depends_on    = [aws_internet_gateway.primary]
}

resource "aws_route_table" "primary_public" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.primary.id
  }
  tags = { Name = "${var.project_name}-primary-public-rt" }
}

resource "aws_route_table_association" "primary_public" {
  provider       = aws.primary
  count          = 2
  subnet_id      = aws_subnet.primary_public[count.index].id
  route_table_id = aws_route_table.primary_public.id
}

resource "aws_route_table" "primary_private" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.primary.id
  }
  tags = { Name = "${var.project_name}-primary-private-rt" }
}

resource "aws_route_table_association" "primary_private" {
  provider       = aws.primary
  count          = 2
  subnet_id      = aws_subnet.primary_private[count.index].id
  route_table_id = aws_route_table.primary_private.id
}

resource "aws_route_table" "primary_database" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary.id
  tags     = { Name = "${var.project_name}-primary-database-rt" }
}

resource "aws_route_table_association" "primary_database" {
  provider       = aws.primary
  count          = 2
  subnet_id      = aws_subnet.primary_database[count.index].id
  route_table_id = aws_route_table.primary_database.id
}

###############################################################################
# SECONDARY REGION — VPC
###############################################################################

resource "aws_vpc" "secondary" {
  provider             = aws.secondary
  cidr_block           = var.secondary_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project_name}-secondary-vpc" }
}

resource "aws_internet_gateway" "secondary" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary.id
  tags     = { Name = "${var.project_name}-secondary-igw" }
}

resource "aws_subnet" "secondary_public" {
  provider                = aws.secondary
  count                   = 2
  vpc_id                  = aws_vpc.secondary.id
  cidr_block              = cidrsubnet(var.secondary_vpc_cidr, 8, count.index)
  availability_zone       = local.secondary_azs[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project_name}-secondary-public-${local.secondary_azs[count.index]}" }
}

resource "aws_subnet" "secondary_private" {
  provider          = aws.secondary
  count             = 2
  vpc_id            = aws_vpc.secondary.id
  cidr_block        = cidrsubnet(var.secondary_vpc_cidr, 8, count.index + 10)
  availability_zone = local.secondary_azs[count.index]
  tags              = { Name = "${var.project_name}-secondary-private-${local.secondary_azs[count.index]}" }
}

resource "aws_subnet" "secondary_database" {
  provider          = aws.secondary
  count             = 2
  vpc_id            = aws_vpc.secondary.id
  cidr_block        = cidrsubnet(var.secondary_vpc_cidr, 8, count.index + 20)
  availability_zone = local.secondary_azs[count.index]
  tags              = { Name = "${var.project_name}-secondary-database-${local.secondary_azs[count.index]}" }
}

resource "aws_eip" "secondary_nat" {
  provider = aws.secondary
  domain   = "vpc"
  tags     = { Name = "${var.project_name}-secondary-nat-eip" }
}

resource "aws_nat_gateway" "secondary" {
  provider      = aws.secondary
  allocation_id = aws_eip.secondary_nat.id
  subnet_id     = aws_subnet.secondary_public[0].id
  tags          = { Name = "${var.project_name}-secondary-nat" }
  depends_on    = [aws_internet_gateway.secondary]
}

resource "aws_route_table" "secondary_public" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.secondary.id
  }
  tags = { Name = "${var.project_name}-secondary-public-rt" }
}

resource "aws_route_table_association" "secondary_public" {
  provider       = aws.secondary
  count          = 2
  subnet_id      = aws_subnet.secondary_public[count.index].id
  route_table_id = aws_route_table.secondary_public.id
}

resource "aws_route_table" "secondary_private" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.secondary.id
  }
  tags = { Name = "${var.project_name}-secondary-private-rt" }
}

resource "aws_route_table_association" "secondary_private" {
  provider       = aws.secondary
  count          = 2
  subnet_id      = aws_subnet.secondary_private[count.index].id
  route_table_id = aws_route_table.secondary_private.id
}

resource "aws_route_table" "secondary_database" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary.id
  tags     = { Name = "${var.project_name}-secondary-database-rt" }
}

resource "aws_route_table_association" "secondary_database" {
  provider       = aws.secondary
  count          = 2
  subnet_id      = aws_subnet.secondary_database[count.index].id
  route_table_id = aws_route_table.secondary_database.id
}

###############################################################################
# Security Groups — Primary
###############################################################################

resource "aws_security_group" "primary_alb" {
  provider    = aws.primary
  name        = "${var.project_name}-primary-alb-sg"
  description = "Primary ALB security group"
  vpc_id      = aws_vpc.primary.id
  tags        = { Name = "${var.project_name}-primary-alb-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "primary_alb_http" {
  provider          = aws.primary
  security_group_id = aws_security_group.primary_alb.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "primary_alb_https" {
  provider          = aws.primary
  security_group_id = aws_security_group.primary_alb.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "primary_alb_all" {
  provider          = aws.primary
  security_group_id = aws_security_group.primary_alb.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "primary_app" {
  provider    = aws.primary
  name        = "${var.project_name}-primary-app-sg"
  description = "Primary App security group"
  vpc_id      = aws_vpc.primary.id
  tags        = { Name = "${var.project_name}-primary-app-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "primary_app_from_alb" {
  provider                     = aws.primary
  security_group_id            = aws_security_group.primary_app.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.primary_alb.id
}

resource "aws_vpc_security_group_egress_rule" "primary_app_all" {
  provider          = aws.primary
  security_group_id = aws_security_group.primary_app.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "primary_db" {
  provider    = aws.primary
  name        = "${var.project_name}-primary-db-sg"
  description = "Primary DB security group"
  vpc_id      = aws_vpc.primary.id
  tags        = { Name = "${var.project_name}-primary-db-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "primary_db_from_app" {
  provider                     = aws.primary
  security_group_id            = aws_security_group.primary_db.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.primary_app.id
}

resource "aws_vpc_security_group_egress_rule" "primary_db_all" {
  provider          = aws.primary
  security_group_id = aws_security_group.primary_db.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

###############################################################################
# Security Groups — Secondary
###############################################################################

resource "aws_security_group" "secondary_alb" {
  provider    = aws.secondary
  name        = "${var.project_name}-secondary-alb-sg"
  description = "Secondary ALB security group"
  vpc_id      = aws_vpc.secondary.id
  tags        = { Name = "${var.project_name}-secondary-alb-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "secondary_alb_http" {
  provider          = aws.secondary
  security_group_id = aws_security_group.secondary_alb.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "secondary_alb_https" {
  provider          = aws.secondary
  security_group_id = aws_security_group.secondary_alb.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "secondary_alb_all" {
  provider          = aws.secondary
  security_group_id = aws_security_group.secondary_alb.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "secondary_app" {
  provider    = aws.secondary
  name        = "${var.project_name}-secondary-app-sg"
  description = "Secondary App security group"
  vpc_id      = aws_vpc.secondary.id
  tags        = { Name = "${var.project_name}-secondary-app-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "secondary_app_from_alb" {
  provider                     = aws.secondary
  security_group_id            = aws_security_group.secondary_app.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.secondary_alb.id
}

resource "aws_vpc_security_group_egress_rule" "secondary_app_all" {
  provider          = aws.secondary
  security_group_id = aws_security_group.secondary_app.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "secondary_db" {
  provider    = aws.secondary
  name        = "${var.project_name}-secondary-db-sg"
  description = "Secondary DB security group"
  vpc_id      = aws_vpc.secondary.id
  tags        = { Name = "${var.project_name}-secondary-db-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "secondary_db_from_app" {
  provider                     = aws.secondary
  security_group_id            = aws_security_group.secondary_db.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.secondary_app.id
}

resource "aws_vpc_security_group_egress_rule" "secondary_db_all" {
  provider          = aws.secondary
  security_group_id = aws_security_group.secondary_db.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

###############################################################################
# ALB — Primary
###############################################################################

resource "aws_lb" "primary" {
  provider           = aws.primary
  name               = "${var.project_name}-primary-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.primary_alb.id]
  subnets            = aws_subnet.primary_public[*].id

  enable_deletion_protection = false
  drop_invalid_header_fields = true

  tags = { Name = "${var.project_name}-primary-alb" }
}

resource "aws_lb_target_group" "primary" {
  provider = aws.primary
  name     = "${var.project_name}-primary-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.primary.id

  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = { Name = "${var.project_name}-primary-tg" }
}

resource "aws_lb_listener" "primary_http" {
  provider          = aws.primary
  load_balancer_arn = aws_lb.primary.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.primary.arn
  }
}

###############################################################################
# ALB — Secondary
###############################################################################

resource "aws_lb" "secondary" {
  provider           = aws.secondary
  name               = "${var.project_name}-secondary-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.secondary_alb.id]
  subnets            = aws_subnet.secondary_public[*].id

  enable_deletion_protection = false
  drop_invalid_header_fields = true

  tags = { Name = "${var.project_name}-secondary-alb" }
}

resource "aws_lb_target_group" "secondary" {
  provider = aws.secondary
  name     = "${var.project_name}-secondary-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.secondary.id

  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = { Name = "${var.project_name}-secondary-tg" }
}

resource "aws_lb_listener" "secondary_http" {
  provider          = aws.secondary
  load_balancer_arn = aws_lb.secondary.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.secondary.arn
  }
}

###############################################################################
# RDS — Primary
###############################################################################

resource "aws_db_subnet_group" "primary" {
  provider   = aws.primary
  name       = "${var.project_name}-primary-db-subnet"
  subnet_ids = aws_subnet.primary_database[*].id
  tags       = { Name = "${var.project_name}-primary-db-subnet-group" }
}

resource "aws_db_instance" "primary" {
  provider   = aws.primary
  identifier = "${var.project_name}-primary-db"

  engine         = "postgres"
  engine_version = "16.4"
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  multi_az               = false
  db_subnet_group_name   = aws_db_subnet_group.primary.name
  vpc_security_group_ids = [aws_security_group.primary_db.id]

  backup_retention_period = 7
  skip_final_snapshot     = true
  deletion_protection     = false

  # Required for cross-region read replica
  backup_window      = "03:00-04:00"
  maintenance_window = "Mon:04:00-Mon:05:00"

  tags = { Name = "${var.project_name}-primary-db" }
}

###############################################################################
# RDS — Cross-Region Read Replica
###############################################################################

resource "aws_db_subnet_group" "secondary" {
  provider   = aws.secondary
  name       = "${var.project_name}-secondary-db-subnet"
  subnet_ids = aws_subnet.secondary_database[*].id
  tags       = { Name = "${var.project_name}-secondary-db-subnet-group" }
}

resource "aws_db_instance" "secondary" {
  provider   = aws.secondary
  identifier = "${var.project_name}-secondary-db"

  replicate_source_db = aws_db_instance.primary.arn
  instance_class      = var.db_instance_class

  storage_encrypted = true
  storage_type      = "gp3"

  multi_az               = false
  db_subnet_group_name   = aws_db_subnet_group.secondary.name
  vpc_security_group_ids = [aws_security_group.secondary_db.id]

  skip_final_snapshot = true
  deletion_protection = false

  tags = { Name = "${var.project_name}-secondary-db" }
}

###############################################################################
# S3 — Cross-Region Replication
###############################################################################

resource "aws_iam_role" "s3_replication" {
  name = "${var.project_name}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
    }]
  })

  tags = { Name = "${var.project_name}-s3-replication-role" }
}

resource "aws_iam_role_policy" "s3_replication" {
  name = "${var.project_name}-s3-replication"
  role = aws_iam_role.s3_replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
        ]
        Resource = [aws_s3_bucket.primary.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging",
        ]
        Resource = ["${aws_s3_bucket.primary.arn}/*"]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
        ]
        Resource = ["${aws_s3_bucket.secondary.arn}/*"]
      }
    ]
  })
}

resource "aws_s3_bucket" "primary" {
  provider      = aws.primary
  bucket        = "${var.project_name}-primary-${local.account_id}"
  force_destroy = true
  tags          = { Name = "${var.project_name}-primary-bucket" }
}

resource "aws_s3_bucket_versioning" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket" "secondary" {
  provider      = aws.secondary
  bucket        = "${var.project_name}-secondary-${local.account_id}"
  force_destroy = true
  tags          = { Name = "${var.project_name}-secondary-bucket" }
}

resource "aws_s3_bucket_versioning" "secondary" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secondary" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_replication_configuration" "primary" {
  provider = aws.primary

  role   = aws_iam_role.s3_replication.arn
  bucket = aws_s3_bucket.primary.id

  rule {
    id     = "replicate-all"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.secondary.arn
      storage_class = "STANDARD"
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.primary,
    aws_s3_bucket_versioning.secondary,
  ]
}

###############################################################################
# ACM Certificates
###############################################################################

resource "aws_acm_certificate" "primary" {
  provider          = aws.primary
  domain_name       = var.site_domain
  validation_method = "DNS"

  lifecycle { create_before_destroy = true }
  tags = { Name = "${var.project_name}-primary-cert" }
}

resource "aws_acm_certificate" "secondary" {
  provider          = aws.secondary
  domain_name       = var.site_domain
  validation_method = "DNS"

  lifecycle { create_before_destroy = true }
  tags = { Name = "${var.project_name}-secondary-cert" }
}

# DNS validation records (shared zone, deduplicated)
resource "aws_route53_record" "cert_validation_primary" {
  for_each = {
    for dvo in aws_acm_certificate.primary.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "primary" {
  provider                = aws.primary
  certificate_arn         = aws_acm_certificate.primary.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_primary : record.fqdn]
}

resource "aws_acm_certificate_validation" "secondary" {
  provider                = aws.secondary
  certificate_arn         = aws_acm_certificate.secondary.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_primary : record.fqdn]
}

###############################################################################
# Route53 Health Checks
###############################################################################

resource "aws_route53_health_check" "primary" {
  fqdn              = aws_lb.primary.dns_name
  port               = 80
  type               = "HTTP"
  resource_path      = "/health"
  failure_threshold  = 3
  request_interval   = 30
  measure_latency    = true

  tags = { Name = "${var.project_name}-primary-health-check" }
}

resource "aws_route53_health_check" "secondary" {
  fqdn              = aws_lb.secondary.dns_name
  port               = 80
  type               = "HTTP"
  resource_path      = "/health"
  failure_threshold  = 3
  request_interval   = 30
  measure_latency    = true

  tags = { Name = "${var.project_name}-secondary-health-check" }
}

###############################################################################
# Route53 Failover Records
###############################################################################

resource "aws_route53_record" "primary" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.site_domain
  type    = "A"

  failover_routing_policy {
    type = "PRIMARY"
  }

  alias {
    name                   = aws_lb.primary.dns_name
    zone_id                = aws_lb.primary.zone_id
    evaluate_target_health = true
  }

  set_identifier  = "primary"
  health_check_id = aws_route53_health_check.primary.id
}

resource "aws_route53_record" "secondary" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.site_domain
  type    = "A"

  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = aws_lb.secondary.dns_name
    zone_id                = aws_lb.secondary.zone_id
    evaluate_target_health = true
  }

  set_identifier  = "secondary"
  health_check_id = aws_route53_health_check.secondary.id
}

###############################################################################
# CloudWatch Alarms — Failover Triggers
###############################################################################

resource "aws_cloudwatch_metric_alarm" "primary_health" {
  provider            = aws.primary
  alarm_name          = "${var.project_name}-primary-unhealthy"
  alarm_description   = "Primary region health check failed"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    LoadBalancer = aws_lb.primary.arn_suffix
    TargetGroup  = aws_lb_target_group.primary.arn_suffix
  }

  alarm_actions = []

  tags = { Name = "${var.project_name}-primary-health-alarm" }
}

resource "aws_cloudwatch_metric_alarm" "secondary_health" {
  provider            = aws.secondary
  alarm_name          = "${var.project_name}-secondary-unhealthy"
  alarm_description   = "Secondary region health check failed"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    LoadBalancer = aws_lb.secondary.arn_suffix
    TargetGroup  = aws_lb_target_group.secondary.arn_suffix
  }

  alarm_actions = []

  tags = { Name = "${var.project_name}-secondary-health-alarm" }
}
