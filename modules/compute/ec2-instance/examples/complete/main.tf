provider "aws" {
  region = var.aws_region
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "ec2_instance" {
  source = "../../"

  project     = var.project
  environment = var.environment

  ami_id             = data.aws_ami.amazon_linux_2.id
  instance_type      = var.instance_type
  subnet_id          = var.subnet_id
  security_group_ids = var.security_group_ids
  key_name           = var.key_name

  root_volume_type      = "gp3"
  root_volume_size      = 30
  root_volume_encrypted = true

  enable_detailed_monitoring = true
  associate_eip              = var.associate_eip
  ebs_optimized              = true

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y amazon-cloudwatch-agent
  EOF

  team        = var.team
  cost_center = var.cost_center
  repository  = var.repository
}
