data "aws_partition" "current" {}

# Node Group IAM Role
resource "aws_iam_role" "node" {
  name = "${local.node_group_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.node_group_name}-node-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "worker_node" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "cni" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "ssm" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node.name
}

# Managed Node Group
resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = local.node_group_name
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids

  instance_types = var.instance_types
  ami_type       = var.ami_type
  capacity_type  = var.capacity_type
  disk_size      = var.disk_size

  labels = var.labels

  scaling_config {
    min_size     = var.min_size
    max_size     = var.max_size
    desired_size = var.desired_size
  }

  update_config {
    max_unavailable            = var.max_unavailable_percentage == null ? var.max_unavailable : null
    max_unavailable_percentage = var.max_unavailable_percentage
  }

  dynamic "taint" {
    for_each = var.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  dynamic "remote_access" {
    for_each = var.ssh_key_name != null ? [1] : []
    content {
      ec2_ssh_key               = var.ssh_key_name
      source_security_group_ids = var.ssh_security_group_ids
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.node_group_name
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.worker_node,
    aws_iam_role_policy_attachment.cni,
    aws_iam_role_policy_attachment.ecr_read,
    aws_iam_role_policy_attachment.ssm,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}
