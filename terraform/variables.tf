variable "aws_region" {
  default = "eu-central-1"
  type = string
  description = "AWS region"
}

variable "project_name" {
  default = "ecs-nginx-demo"
}

variable"repository_name" {
description = "Name of the ECR repository"
type = string
default = "custom-web"
}

variable "environment" {
description = "Environment name"
type = string
default = "dev"
}