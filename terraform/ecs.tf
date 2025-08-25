resource "aws_ecs_cluster" "web_container" {
  name = "web_container"
}

resource "aws_ecs_task_definition" "web_container" {
  family                = "web_container"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "256"
  memory = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name = "web"
      image = aws_ecr_repository.custom_web.repository_url
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

resource "aws_ecs_service" "web_container" {
  name = "lesson7_vrba"
  cluster = aws_ecs_cluster.web_container.id
  task_definition = aws_ecs_task_definition.web_container.arn
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
        "awslogs-group" = aws_cloudwatch_log_group.web_log_group.name
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
    target_group_arn = aws_lb_target_group.web_group.arn
    container_name = "nginx"
    container_port = 80
  }

  depends_on = [aws_lb_listener.web]

  tags = {
    Name = "${var.project_name}-service"
  }
}
