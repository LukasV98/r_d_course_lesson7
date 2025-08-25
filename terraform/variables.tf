variable "aws_region" {
  default = "eu-central-1"
  type = string
  description = "AWS region"
}

variable "project_name" {
  default = "ecs-nginx-demo"
}

variable "repository_name" {
description = "Name of the ECR repository"
type = string
default = "custom-web"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "example-app"
}

variable "alert_email" {
  description = "Email for alerts"
  type        = string
  default = "wixikm@gmail.com"
}
