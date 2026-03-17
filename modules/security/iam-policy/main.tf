###############################################################################
# IAM Policy Document
###############################################################################

data "aws_iam_policy_document" "this" {
  dynamic "statement" {
    for_each = var.policy_statements
    content {
      sid       = statement.value.sid
      effect    = statement.value.effect
      actions   = length(statement.value.actions) > 0 ? statement.value.actions : null
      resources = length(statement.value.resources) > 0 ? statement.value.resources : null

      not_actions   = length(statement.value.not_actions) > 0 ? statement.value.not_actions : null
      not_resources = length(statement.value.not_resources) > 0 ? statement.value.not_resources : null

      dynamic "principals" {
        for_each = statement.value.principals
        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "not_principals" {
        for_each = statement.value.not_principals
        content {
          type        = not_principals.value.type
          identifiers = not_principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = statement.value.conditions
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

###############################################################################
# IAM Policy
###############################################################################

resource "aws_iam_policy" "this" {
  name        = "${local.name_prefix}-${var.name}"
  description = var.description
  path        = var.path
  policy      = data.aws_iam_policy_document.this.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${var.name}"
  })
}
