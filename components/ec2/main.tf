###############################################################################
# EC2 Component — EC2 Instance with Security Group, EBS, User Data, EIP
###############################################################################

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "components/ec2/terraform.tfstate"
  #   region         = "ap-south-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Component   = "ec2"
    }
  }
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_ami" "amazon_linux_2023" {
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

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_key_pair" "selected" {
  key_name           = var.key_pair_name
  include_public_key = true
}

# -----------------------------------------------------------------------------
# Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "instance" {
  name        = "${var.project_name}-${var.environment}-ec2-sg"
  description = "Security group for EC2 instance"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.instance.id
  description       = "SSH access from allowed CIDRs"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.ssh_allowed_cidr

  tags = {
    Name = "ssh-ingress"
  }
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.instance.id
  description       = "HTTP access"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "http-ingress"
  }
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.instance.id
  description       = "HTTPS access"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "https-ingress"
  }
}

resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.instance.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "all-outbound"
  }
}

# -----------------------------------------------------------------------------
# IAM Instance Profile
# -----------------------------------------------------------------------------

resource "aws_iam_role" "instance" {
  name = "${var.project_name}-${var.environment}-ec2-role"

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

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "instance" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.instance.name

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-profile"
  }
}

# -----------------------------------------------------------------------------
# EC2 Instance
# -----------------------------------------------------------------------------

resource "aws_instance" "main" {
  ami                    = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  key_name               = data.aws_key_pair.selected.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.instance.id]
  iam_instance_profile   = aws_iam_instance_profile.instance.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name = "${var.project_name}-${var.environment}-root-vol"
    }
  }

  user_data = base64encode(<<-USERDATA
    #!/bin/bash
    set -euxo pipefail

    # Update system packages
    dnf update -y

    # Install and start nginx
    dnf install -y nginx
    systemctl enable nginx
    systemctl start nginx

    # Create a custom index page
    cat > /usr/share/nginx/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html>
    <head><title>${var.project_name} - ${var.environment}</title></head>
    <body>
      <h1>Welcome to ${var.project_name}</h1>
      <p>Environment: ${var.environment}</p>
      <p>Instance provisioned by Terraform</p>
    </body>
    </html>
    HTML

    # Install CloudWatch agent
    dnf install -y amazon-cloudwatch-agent

    # Signal successful provisioning
    echo "User data script completed successfully" > /var/log/user-data-complete.log
  USERDATA
  )

  user_data_replace_on_change = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring = var.detailed_monitoring

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

# -----------------------------------------------------------------------------
# Additional EBS Volume
# -----------------------------------------------------------------------------

resource "aws_ebs_volume" "data" {
  count = var.data_volume_size > 0 ? 1 : 0

  availability_zone = aws_instance.main.availability_zone
  size              = var.data_volume_size
  type              = "gp3"
  encrypted         = true
  iops              = var.data_volume_iops
  throughput        = var.data_volume_throughput

  tags = {
    Name = "${var.project_name}-${var.environment}-data-vol"
  }
}

resource "aws_volume_attachment" "data" {
  count = var.data_volume_size > 0 ? 1 : 0

  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.data[0].id
  instance_id = aws_instance.main.id
}

# -----------------------------------------------------------------------------
# Elastic IP
# -----------------------------------------------------------------------------

resource "aws_eip" "instance" {
  count  = var.assign_elastic_ip ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-eip"
  }
}

resource "aws_eip_association" "instance" {
  count = var.assign_elastic_ip ? 1 : 0

  instance_id   = aws_instance.main.id
  allocation_id = aws_eip.instance[0].id
}

# -----------------------------------------------------------------------------
# CloudWatch Alarms
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-ec2-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EC2 CPU utilization exceeds 80%"
  treat_missing_data  = "missing"

  dimensions = {
    InstanceId = aws_instance.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-cpu-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "status_check" {
  alarm_name          = "${var.project_name}-${var.environment}-ec2-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "EC2 instance status check failed"
  treat_missing_data  = "breaching"

  dimensions = {
    InstanceId = aws_instance.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-status-alarm"
  }
}
