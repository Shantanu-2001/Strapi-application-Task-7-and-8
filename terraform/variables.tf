variable "aws_region" {
  default = "ap-south-1"
}

variable "docker_image" {
  description = "ECR image pushed by CI"
  type        = string
}

variable "ecs_execution_role_arn" {
  description = "Pre-existing ECS execution role ARN"
  type        = string
}
