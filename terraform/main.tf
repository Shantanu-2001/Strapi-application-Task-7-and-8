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
# Provider
# -------------------------
provider "aws" {
  region = var.aws_region
}

# -------------------------
# Data
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
# IAM — ECS ROLES
# =========================================================
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "strapi-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_task_execution_cloudwatch" {
  name = "strapi-ecs-cloudwatch-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/ecs/*"
    }]
  })
}

resource "aws_iam_role" "ecs_task_role" {
  name = "strapi-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# =========================================================
# ECS CLUSTER
# =========================================================
resource "aws_ecs_cluster" "strapi" {
  name = "strapi-cluster-shantanu"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# =========================================================
# ECS SECURITY GROUP
# =========================================================
resource "aws_security_group" "ecs_sg" {
  name   = "strapi-ecs-sg-shantanu"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# =========================================================
# CLOUDWATCH LOG GROUP
# =========================================================
resource "aws_cloudwatch_log_group" "strapi" {
  name              = "/ecs/strapi"
  retention_in_days = 7
}

# =========================================================
# RDS
# =========================================================
resource "aws_db_subnet_group" "strapi_db_subnet_group" {
  name       = "strapi-db-subnet-group-shantanu"
  subnet_ids = data.aws_subnets.default.ids
}

resource "aws_security_group" "strapi_rds_sg" {
  name   = "strapi-rds-sg"
  vpc_id = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ecs_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.strapi_rds_sg.id
  source_security_group_id = aws_security_group.ecs_sg.id
}

resource "aws_db_instance" "strapi_rds" {
  identifier          = "strapi-db"
  engine              = "postgres"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  username            = "strapi"
  password            = "strapi123"
  db_name             = "strapi_db"
  skip_final_snapshot = true

  db_subnet_group_name   = aws_db_subnet_group.strapi_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.strapi_rds_sg.id]
}

# =========================================================
# ECS TASK DEFINITION  ✅ FIXED
# =========================================================
resource "aws_ecs_task_definition" "strapi" {
  family                   = "strapi-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name  = "strapi"
    image = var.docker_image

    portMappings = [{
      containerPort = 1337
      protocol      = "tcp"
    }]

    environment = [
      { name = "NODE_ENV", value = "production" },
      { name = "HOST", value = "0.0.0.0" },
      { name = "PORT", value = "1337" },

      # -------- REQUIRED STRAPI SECRETS --------
      { name = "APP_KEYS", value = "key1,key2,key3,key4" },
      { name = "API_TOKEN_SALT", value = "api_token_salt_123456" },
      { name = "ADMIN_JWT_SECRET", value = "admin_jwt_secret_123456" },
      { name = "JWT_SECRET", value = "jwt_secret_123456" },

      # -------- DATABASE --------
      { name = "DATABASE_CLIENT", value = "postgres" },
      { name = "DATABASE_HOST", value = aws_db_instance.strapi_rds.address },
      { name = "DATABASE_PORT", value = "5432" },
      { name = "DATABASE_NAME", value = "strapi_db" },
      { name = "DATABASE_USERNAME", value = "strapi" },
      { name = "DATABASE_PASSWORD", value = "strapi123" }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.strapi.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "strapi"
      }
    }
  }])
}

# =========================================================
# ECS SERVICE
# =========================================================
resource "aws_ecs_service" "strapi" {
  name            = "strapi-service"
  cluster         = aws_ecs_cluster.strapi.id
  task_definition = aws_ecs_task_definition.strapi.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  depends_on = [
    aws_db_instance.strapi_rds
  ]
}
