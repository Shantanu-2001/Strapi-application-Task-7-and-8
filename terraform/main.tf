terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.3.0"

  backend "s3" {
    bucket = "shantanu-terraform-state-1"
    key    = "terraform/ecs-fargate.tfstate"
    region = "ap-south-1"
  }
}

# -------------------------
# AWS Provider
# -------------------------
provider "aws" {
  region = var.aws_region
}

# -------------------------
# Account / Network Data
# -------------------------
data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# =========================================================
# IAM — ECS TASK EXECUTION ROLE (ONLY ADDITION)
# =========================================================

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole-strapi"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
