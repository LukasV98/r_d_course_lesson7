terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "aws-bucket-vrba"
    key = "ecs-demo/terraform.tfstate"
    region = "eu-central-1"
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_subnets" "eccsubnets" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.myvpc.id]
  }
}

data "aws_vpc" "myvpc" {
  default = true
}

data "aws_subnets" "albsubnets" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.myvpc.id]
  }
}

resource "aws_security_group" "alb" {
  name = "${var.project_name}-alb-sg"
  description = "Security group ALB"
  vpc_id = data.aws_vpc.myvpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-slb-sg"
  }
}

resource "aws_security_group" "ecs_tasks" {
  name = "${var.project_name}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id = data.aws_vpc.myvpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-tasks-sg"
  }
}

resource "aws_lb" "main" {
  name = "${var.project_name}-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb.id]
  subnets = data.aws_subnets.albsubnets.ids
  tags = {
    Name = "${var.project_name}-alb"
  }
}

resource "aws_lb_target_group" "main" {
  name = "${var.project_name}-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = data.aws_vpc.myvpc.id
  target_type = "ip"

  health_check {
    path = "/"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

resource "aws_ecs_cluster" "lesson7" {
  name = "lesson7"
}

resource "aws_ecs_task_definition" "lesson7" {
  family                = "lesson7"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "256"
  memory = "512"
  container_definitions = jsonencode([
    {
      name = "web"
      image = "nginx:latest"
      portMappings = [
       {
         containerPort = 80
         hostPort = 80
         protocol = "tcp"
       }
      ]
    }
  ])
}

resource "aws_ecs_service" "lesson7" {
  name = "lesson7_vrba"
  cluster = aws_ecs_cluster.lesson7.id
  task_definition = aws_ecs_task_definition.lesson7.arn
  desired_count = 1
  launch_type = "FARGATE"

  network_configuration {
    subnets = [data.aws_subnets.eccsubnets.ids[0], data.aws_subnets.eccsubnets.ids[0]]
    security_groups = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name = "web"
    container_port = 80
  }
}

resource "aws_lb_target_group" "nginx" {
  name = "${var.project_name}-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = data.aws_vpc.myvpc.id
  target_type = "ip"

  health_check {
    enabled = true
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    interval = 30
    path = "/"
    matcher = "200"
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

resource "aws_lb_listener" "nginx" {
  load_balancer_arn = aws_lb.main.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "nginx" {
  name = "/ecs/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-logs"
  }
}

resource "aws_ecs_task_definition" "nginx" {
  family = "${var.project_name}-task"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "256"
  memory = "512"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name = "nginx"
    image =  "nginx:alpine"

    portMappings = [{
      containerPort = 80
      protocol = "tcp"  }]

    logConfirmation = {
      logDriver = "awslogs"
      option = {
        "awslogs-group" = aws_cloudwatch_log_group.nginx.name
        "awslogs-region" = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }

    essential = true }])
  tags = {
    Name = "${var.project_name}-task"
  }
}

resource "aws_ecs_service" "nginx" {
  name = "${var.project_name}-service"
  cluster = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.nginx.arn
  desired_count = 1
  launch_type = "FARGATE"
  network_configuration {
    subnets = data.aws_subnets.eccsubnets.ids[*]
    security_groups = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx.arn
    container_name = "nginx"
    container_port = 80
  }

  depends_on = [aws_lb_listener.nginx]

  tags = {
    Name = "${var.project_name}-service"
  }
}

