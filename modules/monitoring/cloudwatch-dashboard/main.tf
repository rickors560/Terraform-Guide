################################################################################
# CloudWatch Dashboard
################################################################################

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = local.dashboard_name
  dashboard_body = local.dashboard_body
}
