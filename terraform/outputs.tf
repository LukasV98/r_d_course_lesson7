output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value = aws_lb.main.dns_name
}

output "load_balancer_url" {
  description = "URL of the load balancer"
  value = "http://${aws_lb.main.dns_name}"
}

output "instance_public_ip" {
  value = ""                                          # The actual value to be outputted
  description = "The public IP address of the EC2 instance" # Description of what this output represents
}

output "ecr_repository_url" {
description = "URL of the ECR repository"
value = aws_ecr_repository.custom_web.repository_url
}

output "ecr_repository_arn" {
description = "ARN of the ECR repository"
value = aws_ecr_repository.custom_web.arn
}