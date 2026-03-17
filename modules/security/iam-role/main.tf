###############################################################################
# IAM Role
###############################################################################

resource "aws_iam_role" "this" {
  name                 = "${local.name_prefix}-${var.name}"
  description          = var.description
  path                 = var.path
  max_session_duration = var.max_session_duration
  permissions_boundary = var.permissions_boundary_arn
  force_detach_policies = var.force_detach_policies

  assume_role_policy = local.assume_role_policy

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${var.name}"
  })
}

###############################################################################
# Managed Policy Attachments
###############################################################################

resource "aws_iam_role_policy_attachment" "managed" {
  count = length(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = var.managed_policy_arns[count.index]
}

###############################################################################
# Inline Policies
###############################################################################

resource "aws_iam_role_policy" "inline" {
  for_each = var.inline_policies

  name   = each.key
  role   = aws_iam_role.this.id
  policy = each.value
}

###############################################################################
# Instance Profile (optional)
###############################################################################

resource "aws_iam_instance_profile" "this" {
  count = var.create_instance_profile ? 1 : 0

  name = "${local.name_prefix}-${var.name}"
  path = var.path
  role = aws_iam_role.this.name

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${var.name}"
  })
}
