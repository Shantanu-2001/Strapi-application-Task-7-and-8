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

      portMappings = [
        {
          containerPort = 1337
          protocol      = "tcp"
        }
      ]

      environment = [
        # =========================
        # STRAPI CORE
        # =========================
        { name = "NODE_ENV", value = "production" },
        { name = "HOST", value = "0.0.0.0" },
        { name = "PORT", value = "1337" },

        # =========================
        # DATABASE CONFIG (RDS POSTGRES)
        # =========================
        { name = "DATABASE_CLIENT", value = "postgres" },
        { name = "DATABASE_HOST", value = aws_db_instance.strapi.address },
        { name = "DATABASE_PORT", value = "5432" },
        { name = "DATABASE_NAME", value = "strapi_db" },
        { name = "DATABASE_USERNAME", value = "strapi" },
        { name = "DATABASE_PASSWORD", value = "strapi123" },

        #  REQUIRED FOR AWS RDS (SSL)
        { name = "DATABASE_SSL", value = "true" },
        { name = "DATABASE_SSL__REJECT_UNAUTHORIZED", value = "false" },

        # =========================
        # STRAPI PRODUCTION SECRETS (MANDATORY)
        # =========================
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

  depends_on = [
    aws_db_instance.strapi
  ]
}
