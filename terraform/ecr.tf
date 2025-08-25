resource "aws_ecr_repository" "custom_web" {
  name                 = var.repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.environment
    Project     = "DevOps-Course"
    Lesson      = "5"
  }
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "custom_web_policy" {
  repository = aws_ecr_repository.custom_web.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 1 images"
        selection = {
          tagStatus   = "tagged"
          tagPrefixList = ["v"]
          countType   = "imageCountMoreThan"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
