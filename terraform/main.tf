terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.aws_region
}

# Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security group
resource "aws_security_group" "strapi_sg" {
  name        = "strapi-sg"
  description = "Allow Strapi and SSH"
  vpc_id      = data.aws_vpc.default.id

  # Strapi port 1337
  ingress {
    from_port   = var.strapi_port
    to_port     = var.strapi_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ----------------------------------------------------------
# USER DATA — Install Docker, run PostgreSQL + Strapi
# ----------------------------------------------------------

locals {
  user_data = <<-EOF
              #!/bin/bash

              apt-get update -y
              apt-get install -y docker.io

              systemctl start docker
              systemctl enable docker

              usermod -aG docker ubuntu

              # Pull images
              docker pull postgres:15
              docker pull ${var.docker_image}

              # Run PostgreSQL with correct DB name (strapi_db)
              docker run -d \
                --name strapi-postgres \
                -e POSTGRES_DB=strapi_db \
                -e POSTGRES_USER=strapi \
                -e POSTGRES_PASSWORD=strapi123 \
                -v pgdata:/var/lib/postgresql/data \
                postgres:15

              # Wait for PostgreSQL to initialize
              sleep 12

              # Run Strapi container
              docker run -d -p 1337:1337 \
                --name strapi \
                --link strapi-postgres \
                -e DATABASE_CLIENT=postgres \
                -e DATABASE_HOST=strapi-postgres \
                -e DATABASE_PORT=5432 \
                -e DATABASE_NAME=strapi_db \
                -e DATABASE_USERNAME=strapi \
                -e DATABASE_PASSWORD=strapi123 \
                -e HOST=0.0.0.0 \
                -e PORT=1337 \
                ${var.docker_image}
              EOF
}

# EC2 Instance
resource "aws_instance" "strapi" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]
  key_name               = var.key_name
  associate_public_ip_address = true

  user_data = local.user_data

  tags = {
    Name = "strapi-ubuntu-ec2"
  }
}

