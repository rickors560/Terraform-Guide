###############################################################################
# Security Group
###############################################################################

resource "aws_security_group" "this" {
  name        = "${local.name_prefix}-${var.name}"
  description = var.description
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = var.revoke_rules_on_delete

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${var.name}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

###############################################################################
# Ingress Rules
###############################################################################

resource "aws_security_group_rule" "ingress" {
  count = length(var.ingress_rules)

  type              = "ingress"
  security_group_id = aws_security_group.this.id

  from_port   = var.ingress_rules[count.index].from_port
  to_port     = var.ingress_rules[count.index].to_port
  protocol    = var.ingress_rules[count.index].protocol
  description = var.ingress_rules[count.index].description

  cidr_blocks      = var.ingress_rules[count.index].self ? null : (length(var.ingress_rules[count.index].cidr_blocks) > 0 ? var.ingress_rules[count.index].cidr_blocks : null)
  ipv6_cidr_blocks = var.ingress_rules[count.index].self ? null : (length(var.ingress_rules[count.index].ipv6_cidr_blocks) > 0 ? var.ingress_rules[count.index].ipv6_cidr_blocks : null)

  source_security_group_id = var.ingress_rules[count.index].self ? null : var.ingress_rules[count.index].security_group_id
  self                     = var.ingress_rules[count.index].self ? true : null
}

###############################################################################
# Egress Rules
###############################################################################

resource "aws_security_group_rule" "egress" {
  count = length(var.egress_rules)

  type              = "egress"
  security_group_id = aws_security_group.this.id

  from_port   = var.egress_rules[count.index].from_port
  to_port     = var.egress_rules[count.index].to_port
  protocol    = var.egress_rules[count.index].protocol
  description = var.egress_rules[count.index].description

  cidr_blocks      = var.egress_rules[count.index].self ? null : (length(var.egress_rules[count.index].cidr_blocks) > 0 ? var.egress_rules[count.index].cidr_blocks : null)
  ipv6_cidr_blocks = var.egress_rules[count.index].self ? null : (length(var.egress_rules[count.index].ipv6_cidr_blocks) > 0 ? var.egress_rules[count.index].ipv6_cidr_blocks : null)

  source_security_group_id = var.egress_rules[count.index].self ? null : var.egress_rules[count.index].security_group_id
  self                     = var.egress_rules[count.index].self ? true : null
}
