variable "aws_region" {
  default = "ap-south-1"
}

variable "docker_image" {
  description = "ECR image pushed by CI"
  type        = string
}
