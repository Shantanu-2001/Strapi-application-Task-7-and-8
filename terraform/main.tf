terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.3.0"

  backend "s3" {
    bucket = "shantanu-rana-terraform-state"
    key    = "terraform/ecs-fargate.tfstate"
    region = "ap-south-1"
  }
}

# =========================
# PROVIDER
# =========================
provider "aws" {
  region = var.aws_region
}

# =========================
# DATA
# =========================
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

# =========================
# IAM ROLES FOR ECS
# =========================
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "strapi-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "strapi-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# =========================
# ECS CLUSTER
# =========================
resource "aws_ecs_cluster" "strapi" {
  name = "strapi-cluster-shantanu"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# =========================
# SECURITY GROUP (ECS)
# =========================
resource "aws_security_group" "ecs_sg" {
  name   = "shantanu-strapi-ecs-sg"
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

# =========================
# CLOUDWATCH LOG GROUP
# =========================
resource "aws_cloudwatch_log_group" "strapi" {
  name              = "/ecs/strapi-shantanu"
  retention_in_days = 7
}

# =========================
# RDS (POSTGRES)
# =========================
resource "aws_db_subnet_group" "strapi" {
  name       = "shantanu-strapi-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids
}

resource "aws_security_group" "rds_sg" {
  name   = "shantanu-strapi-rds-sg"
  vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group_rule" "ecs_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = aws_security_group.ecs_sg.id
}

resource "aws_db_instance" "strapi" {
  identifier             = "strapi-db"
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = "strapi"
  password               = "strapi123"
  db_name                = "strapi_db"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.strapi.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}

# =========================
# ECS TASK DEFINITION
# =========================
resource "aws_ecs_task_definition" "strapi" {
  family                   = "strapi-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
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

        { name = "DATABASE_CLIENT", value = "postgres" },
        { name = "DATABASE_HOST", value = aws_db_instance.strapi.address },
        { name = "DATABASE_PORT", value = "5432" },
        { name = "DATABASE_NAME", value = "strapi_db" },
        { name = "DATABASE_USERNAME", value = "strapi" },
        { name = "DATABASE_PASSWORD", value = "strapi123" },

        { name = "DATABASE_SSL", value = "true" },
        { name = "DATABASE_SSL__REJECT_UNAUTHORIZED", value = "false" },

        { name = "APP_KEYS", value = "key1,key2,key3,key4" },
        { name = "API_TOKEN_SALT", value = "api_token_salt_123" },
        { name = "ADMIN_JWT_SECRET", value = "admin_jwt_secret_123" },
        { name = "JWT_SECRET", value = "jwt_secret_123" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.strapi.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "strapi"
        }
      }
    }
  ])
}

# =========================
# ECS SERVICE
# =========================
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

  depends_on = [aws_db_instance.strapi]
}

# =========================
# CLOUDWATCH DASHBOARD (UPDATED)
# =========================
resource "aws_cloudwatch_dashboard" "strapi_dashboard" {
  dashboard_name = "strapi-ecs-dashboard-shantanu"

  dashboard_body = jsonencode({
    widgets = [

      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title   = "ECS CPU Utilization"
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.strapi.name, "ServiceName", aws_ecs_service.strapi.name]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
        }
      },

      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title   = "ECS Memory Utilization"
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.strapi.name, "ServiceName", aws_ecs_service.strapi.name]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
        }
      },

      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title   = "ECS Running Task Count"
          metrics = [
            ["AWS/ECS", "RunningTaskCount", "ClusterName", aws_ecs_cluster.strapi.name, "ServiceName", aws_ecs_service.strapi.name]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
        }
      },

      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title = "Network In / Out (Bytes)"
          metrics = [
            ["AWS/ECS", "NetworkRxBytes", "ClusterName", aws_ecs_cluster.strapi.name, "ServiceName", aws_ecs_service.strapi.name],
            ["AWS/ECS", "NetworkTxBytes", "ClusterName", aws_ecs_cluster.strapi.name, "ServiceName", aws_ecs_service.strapi.name]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
        }
      }

    ]
  })
}

# =========================
# CLOUDWATCH ALARMS
# =========================
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "strapi-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 70
  evaluation_periods  = 2
  period              = 300
  statistic           = "Average"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"

  dimensions = {
    ClusterName = aws_ecs_cluster.strapi.name
    ServiceName = aws_ecs_service.strapi.name
  }
}

resource "aws_cloudwatch_metric_alarm" "high_memory" {
  alarm_name          = "strapi-high-memory"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 75
  evaluation_periods  = 2
  period              = 300
  statistic           = "Average"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"

  dimensions = {
    ClusterName = aws_ecs_cluster.strapi.name
    ServiceName = aws_ecs_service.strapi.name
  }
}
