# -----------------------------------------------------------------------------
# SES Component - Domain Identity, DKIM, SPF/DMARC, Templates, Config Set
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure for remote state:
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "components/ses/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Component   = "ses"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  region      = data.aws_region.current.name
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# SES Domain Identity
# -----------------------------------------------------------------------------

resource "aws_ses_domain_identity" "main" {
  domain = var.domain_name
}

resource "aws_ses_domain_identity_verification" "main" {
  count  = var.create_route53_records ? 1 : 0
  domain = aws_ses_domain_identity.main.id

  depends_on = [aws_route53_record.ses_verification]
}

# -----------------------------------------------------------------------------
# DKIM Configuration
# -----------------------------------------------------------------------------

resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}

# -----------------------------------------------------------------------------
# Route53 Records (Optional)
# -----------------------------------------------------------------------------

data "aws_route53_zone" "main" {
  count = var.create_route53_records ? 1 : 0
  name  = var.route53_zone_name
}

# SES Domain Verification Record
resource "aws_route53_record" "ses_verification" {
  count   = var.create_route53_records ? 1 : 0
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = "_amazonses.${var.domain_name}"
  type    = "TXT"
  ttl     = 600
  records = [aws_ses_domain_identity.main.verification_token]
}

# DKIM Records
resource "aws_route53_record" "dkim" {
  count   = var.create_route53_records ? 3 : 0
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = "${aws_ses_domain_dkim.main.dkim_tokens[count.index]}._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = 600
  records = ["${aws_ses_domain_dkim.main.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

# SPF Record
resource "aws_route53_record" "spf" {
  count   = var.create_route53_records ? 1 : 0
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = var.domain_name
  type    = "TXT"
  ttl     = 600
  records = ["v=spf1 include:amazonses.com ~all"]
}

# DMARC Record
resource "aws_route53_record" "dmarc" {
  count   = var.create_route53_records ? 1 : 0
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = "_dmarc.${var.domain_name}"
  type    = "TXT"
  ttl     = 600
  records = ["v=DMARC1; p=${var.dmarc_policy}; rua=mailto:${var.dmarc_report_email}; ruf=mailto:${var.dmarc_report_email}; fo=1"]
}

# Mail From Domain
resource "aws_ses_domain_mail_from" "main" {
  domain           = aws_ses_domain_identity.main.domain
  mail_from_domain = "mail.${var.domain_name}"
}

resource "aws_route53_record" "mail_from_mx" {
  count   = var.create_route53_records ? 1 : 0
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = aws_ses_domain_mail_from.main.mail_from_domain
  type    = "MX"
  ttl     = 600
  records = ["10 feedback-smtp.${local.region}.amazonses.com"]
}

resource "aws_route53_record" "mail_from_spf" {
  count   = var.create_route53_records ? 1 : 0
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = aws_ses_domain_mail_from.main.mail_from_domain
  type    = "TXT"
  ttl     = 600
  records = ["v=spf1 include:amazonses.com ~all"]
}

# -----------------------------------------------------------------------------
# SES Configuration Set
# -----------------------------------------------------------------------------

resource "aws_ses_configuration_set" "main" {
  name = "${local.name_prefix}-config-set"

  delivery_options {
    tls_policy = "Require"
  }

  reputation_metrics_enabled = true
  sending_enabled            = true
}

# -----------------------------------------------------------------------------
# SNS Topic for SES Events
# -----------------------------------------------------------------------------

resource "aws_sns_topic" "ses_events" {
  name = "${local.name_prefix}-ses-events"

  tags = {
    Name = "${local.name_prefix}-ses-events"
  }
}

resource "aws_sns_topic_policy" "ses_events" {
  arn = aws_sns_topic.ses_events.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSESPublish"
        Effect = "Allow"
        Principal = {
          Service = "ses.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.ses_events.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
        }
      }
    ]
  })
}

# Event Destination - SNS
resource "aws_ses_event_destination" "sns" {
  name                   = "${local.name_prefix}-sns-destination"
  configuration_set_name = aws_ses_configuration_set.main.name
  enabled                = true
  matching_types         = ["bounce", "complaint", "delivery", "reject"]

  sns_destination {
    topic_arn = aws_sns_topic.ses_events.arn
  }
}

# Event Destination - CloudWatch
resource "aws_ses_event_destination" "cloudwatch" {
  name                   = "${local.name_prefix}-cw-destination"
  configuration_set_name = aws_ses_configuration_set.main.name
  enabled                = true
  matching_types         = ["send", "bounce", "complaint", "delivery", "reject", "open", "click"]

  cloudwatch_destination {
    default_value  = "unknown"
    dimension_name = "ses:caller-identity"
    value_source   = "emailHeader"
  }
}

# -----------------------------------------------------------------------------
# SES Email Templates
# -----------------------------------------------------------------------------

resource "aws_ses_template" "welcome" {
  name    = "${local.name_prefix}-welcome"
  subject = "Welcome to ${var.project_name}, {{name}}!"
  html    = <<-HTML
    <!DOCTYPE html>
    <html>
    <head><meta charset="utf-8"></head>
    <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <div style="background-color: #f8f9fa; padding: 20px; text-align: center;">
        <h1 style="color: #333;">Welcome to ${var.project_name}!</h1>
      </div>
      <div style="padding: 20px;">
        <p>Hello {{name}},</p>
        <p>Thank you for joining ${var.project_name}. We are excited to have you on board.</p>
        <p>To get started, please visit your dashboard:</p>
        <p style="text-align: center;">
          <a href="{{dashboardUrl}}" style="background-color: #007bff; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px;">Go to Dashboard</a>
        </p>
        <p>If you have any questions, feel free to reach out to our support team.</p>
        <p>Best regards,<br>The ${var.project_name} Team</p>
      </div>
      <div style="background-color: #f8f9fa; padding: 10px; text-align: center; font-size: 12px; color: #666;">
        <p>This email was sent by ${var.project_name}. Please do not reply to this email.</p>
      </div>
    </body>
    </html>
  HTML
  text    = <<-TEXT
    Welcome to ${var.project_name}!

    Hello {{name}},

    Thank you for joining ${var.project_name}. We are excited to have you on board.

    To get started, visit your dashboard: {{dashboardUrl}}

    If you have any questions, feel free to reach out to our support team.

    Best regards,
    The ${var.project_name} Team
  TEXT
}

resource "aws_ses_template" "password_reset" {
  name    = "${local.name_prefix}-password-reset"
  subject = "${var.project_name} - Password Reset Request"
  html    = <<-HTML
    <!DOCTYPE html>
    <html>
    <head><meta charset="utf-8"></head>
    <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <div style="background-color: #f8f9fa; padding: 20px; text-align: center;">
        <h1 style="color: #333;">Password Reset</h1>
      </div>
      <div style="padding: 20px;">
        <p>Hello {{name}},</p>
        <p>We received a request to reset your password. Click the button below to proceed:</p>
        <p style="text-align: center;">
          <a href="{{resetUrl}}" style="background-color: #dc3545; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px;">Reset Password</a>
        </p>
        <p>This link will expire in {{expiryHours}} hours.</p>
        <p>If you did not request a password reset, please ignore this email or contact support.</p>
        <p>Best regards,<br>The ${var.project_name} Team</p>
      </div>
    </body>
    </html>
  HTML
  text    = <<-TEXT
    Password Reset

    Hello {{name}},

    We received a request to reset your password.

    Reset your password here: {{resetUrl}}

    This link will expire in {{expiryHours}} hours.

    If you did not request a password reset, please ignore this email.

    Best regards,
    The ${var.project_name} Team
  TEXT
}

resource "aws_ses_template" "notification" {
  name    = "${local.name_prefix}-notification"
  subject = "${var.project_name} - {{subject}}"
  html    = <<-HTML
    <!DOCTYPE html>
    <html>
    <head><meta charset="utf-8"></head>
    <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <div style="background-color: #f8f9fa; padding: 20px; text-align: center;">
        <h1 style="color: #333;">{{subject}}</h1>
      </div>
      <div style="padding: 20px;">
        <p>Hello {{name}},</p>
        <p>{{message}}</p>
        <p>Best regards,<br>The ${var.project_name} Team</p>
      </div>
    </body>
    </html>
  HTML
  text    = <<-TEXT
    {{subject}}

    Hello {{name}},

    {{message}}

    Best regards,
    The ${var.project_name} Team
  TEXT
}
