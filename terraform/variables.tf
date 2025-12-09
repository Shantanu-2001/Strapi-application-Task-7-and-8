variable "aws_region" {
  type        = string
  default     = "ap-south-1"
}
 
variable "instance_type" {
  type        = string
  default     = "t2.micro"
}
 
variable "key_name" {
  description = "EC2 key pair name for SSH"
  type        = string
}
 
variable "docker_image" {
  description = "Docker Hub image"
  type        = string
}
 
variable "strapi_port" {
  type        = number
  default     = 1337
}
 
variable "allowed_ssh_cidr" {
  type        = string
  default     = "0.0.0.0/0"
}
