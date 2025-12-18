terraform {
  backend "s3" {
    bucket = "shantanu-rana-terraform-state"
    key    = "terraform/ecs-fargate.tfstate"
    region = "ap-south-1"
  }
}
