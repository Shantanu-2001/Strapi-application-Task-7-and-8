resource "aws_cloudwatch_log_group" "strapi" {
  name              = "/ecs/strapi-shantanu"
  retention_in_days = 7
}

resource "aws_cloudwatch_dashboard" "strapi_dashboard" {
  dashboard_name = "strapi-ecs-dashboard-shantanu"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          title = "ECS CPU Utilization"
          metrics = [["AWS/ECS","CPUUtilization","ClusterName",aws_ecs_cluster.strapi.name,"ServiceName",aws_ecs_service.strapi.name]]
          period = 300
          stat = "Average"
          region = var.aws_region
        }
      },
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          title = "ECS Memory Utilization"
          metrics = [["AWS/ECS","MemoryUtilization","ClusterName",aws_ecs_cluster.strapi.name,"ServiceName",aws_ecs_service.strapi.name]]
          period = 300
          stat = "Average"
          region = var.aws_region
        }
      },
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          title = "ECS Running Task Count"
          metrics = [["AWS/ECS","RunningTaskCount","ClusterName",aws_ecs_cluster.strapi.name,"ServiceName",aws_ecs_service.strapi.name]]
          period = 300
          stat = "Average"
          region = var.aws_region
        }
      },
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          title = "Network In / Out"
          metrics = [
            ["AWS/ECS","NetworkRxBytes","ClusterName",aws_ecs_cluster.strapi.name,"ServiceName",aws_ecs_service.strapi.name],
            ["AWS/ECS","NetworkTxBytes","ClusterName",aws_ecs_cluster.strapi.name,"ServiceName",aws_ecs_service.strapi.name]
          ]
          period = 300
          stat = "Average"
          region = var.aws_region
        }
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "strapi-high-cpu"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 70
  evaluation_periods  = 2
  period              = 300
  statistic           = "Average"

  dimensions = {
    ClusterName = aws_ecs_cluster.strapi.name
    ServiceName = aws_ecs_service.strapi.name
  }
}

resource "aws_cloudwatch_metric_alarm" "high_memory" {
  alarm_name          = "strapi-high-memory"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 75
  evaluation_periods  = 2
  period              = 300
  statistic           = "Average"

  dimensions = {
    ClusterName = aws_ecs_cluster.strapi.name
    ServiceName = aws_ecs_service.strapi.name
  }
}
