provider "aws" {
  region = var.region
}

terraform {
  required_version = "> 0.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.44"
    }
  }

  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}

locals {
  module            = "ec2"
  bucket_policy_arn = data.terraform_remote_state.network.outputs.bucket_policy_arn
  public_subnet_id  = data.terraform_remote_state.network.outputs.public_subnets[0]
  private_subnet_id = data.terraform_remote_state.network.outputs.private_subnets[0]

  sg_ingress_rules = length(var.sg_ingress_rules) > 0 ? var.sg_ingress_rules : [
    {
      "port"     = 80
      "protocol" = "tcp"
      "cidrs"    = ["0.0.0.0/0"]
    },
    {
      "port"     = 443
      "protocol" = "tcp"
      "cidrs"    = ["0.0.0.0/0"]
    },
    {
      "port"     = 22
      "protocol" = "tcp"
      "cidrs"    = ["0.0.0.0/0"]
    }
  ]
}

data "aws_partition" "current" {}

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket  = var.state_bucket
    region  = var.state_region
    key     = "${var.app}/${var.stage}/network/terraform.tfstate"
    profile = ""
  }
}

module "label" {
  source = "../../child-modules/label"
  module = local.module
  app    = var.app
  stage  = var.stage
}

resource "aws_key_pair" "ssh_access_key" {
  key_name   = module.label.name
  public_key = var.ssh_public_key
}

resource "aws_iam_role" "ec2_role" {
  name = module.label.name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "${data.aws_partition.current.partition == "aws-cn" ? "ec2.amazonaws.com.cn" : "ec2.amazonaws.com"}"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = module.label.tags
}

# Instance Profile
resource "aws_iam_instance_profile" "profile" {
  name = module.label.name
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "s3_policy_attach" {
  count      = local.bucket_policy_arn != "" ? 1 : 0
  role       = aws_iam_role.ec2_role.name
  policy_arn = data.terraform_remote_state.network.outputs.bucket_policy_arn
}

# Get Latest AMI
data "aws_ami" "amazon_linux" {
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

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

resource "aws_security_group" "security_group" {
  name        = "${module.label.name}-sg"
  description = "EC2 Security Group"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  dynamic "ingress" {
    for_each = local.sg_ingress_rules
    content {
      from_port   = ingress.value["port"]
      to_port     = ingress.value["port"]
      protocol    = ingress.value["protocol"]
      cidr_blocks = ingress.value["cidrs"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(module.label.tags, { "Name" = module.label.name })
}

resource "aws_eip" "eip" {
  vpc = true

  tags = module.label.tags
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.ec2.id
  allocation_id = aws_eip.eip.id
}

resource "aws_instance" "ec2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.security_group.id]
  subnet_id              = var.public ? local.public_subnet_id : local.private_subnet_id
  iam_instance_profile   = aws_iam_instance_profile.profile.name
  key_name               = aws_key_pair.ssh_access_key.key_name
  
  user_data = <<-EOF
    #!/bin/bash
    set -ex
    sudo yum update -y
    sudo amazon-linux-extras install docker -y
    sudo service docker start
    sudo usermod -a -G docker ec2-user
  EOF


  tags = merge(module.label.tags, { "Name" = module.label.name })

  volume_tags = module.label.tags

  root_block_device {
    volume_size = var.disk_size
  }

  lifecycle {
    create_before_destroy = true
  }
}