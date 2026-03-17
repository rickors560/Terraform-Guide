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
}

module "launch_template" {
  source = "../../"

  project     = var.project
  environment = var.environment

  ami_id        = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  key_name      = var.key_name

  security_group_ids          = var.security_group_ids
  associate_public_ip_address = false

  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      ebs = {
        volume_size           = 30
        volume_type           = "gp3"
        encrypted             = true
        delete_on_termination = true
      }
    }
  ]

  user_data_base64 = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y amazon-cloudwatch-agent
  EOF
  )

  enable_monitoring = true

  team        = var.team
  cost_center = var.cost_center
  repository  = var.repository
}
