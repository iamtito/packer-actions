packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "ami_prefix" {
  type    = string
  default = "packer-aws-ubuntu-java"
}

variable "ghcred" {}

variable "checkout" {
  type = string
  default = "yolox"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "ami" {
  ami_name      = "${var.ami_prefix}-${var.checkout}"
  instance_type = "g4dn.xlarge"
  region        = "us-east-1"
  source_ami_filter {
    filters = {
      name                = "amzn2-ami-ecs-gpu-hvm-2.0.20221118-x86_64-ebs"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["591542846629"]
  }
  launch_block_device_mappings {
    device_name = "/dev/xvda"
    volume_size = 100
    volume_type = "gp2"
    delete_on_termination = true
  }
  ssh_username = "ec2-user"
  tags = {
      Name = "${var.ami_prefix}-${var.checkout}"
  }
}

build {
  name    = "packer-ubuntu"
  sources = [
    "source.amazon-ebs.ami"
  ]

  provisioner "shell" {

    inline = [
      "echo Install Open JDK 8 - START",
      "sleep 10",
      "sudo yum update",
      "sudo yum install -y docker",
      "sudo service docker start",
      "sudo systemctl enable docker",
      "sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /bin/docker-compose && chmod +x /bin/docker-compose && docker-compose --version",
      "echo Install Docker - SUCCESS",
      "git clone https://${var.ghcred}@github.com/iamtito/packer-actions",
    ]
  }
}
