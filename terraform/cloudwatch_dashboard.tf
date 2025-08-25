resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/${var.app_name}"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

resource "aws_cloudwatch_dashboard" "main" {
   dashboard_name = "ecs-service-metrics"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            [
              "AWS/ECS", "CPUUtilization",
              "ClusterName", aws_ecs_cluster.main.name,
              "ServiceName", aws_ecs_service.nginx.name
            ]
          ]
          view     = "timeSeries"
          stacked  = false
          region   = "eu-central-1"
          title    = "ECS CPU Utilization"
          period  = 300
          stat    = "Average"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            [
              "AWS/ECS",
              "MemoryUtilization",
              "ClusterName",  aws_ecs_cluster.main.name,
              "ServiceName", aws_ecs_service.nginx.name
            ]
          ]
          view     = "timeSeries"
          stacked  = false
          region   = "eu-central-1"
          title    = "Memory Utilization"
          period  = 300
          stat    = "Average"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      }
    ]
  })
}


