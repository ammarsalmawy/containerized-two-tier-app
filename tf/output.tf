output "ecr_webapp_url" {
  value = aws_ecr_repository.webapp.repository_url
}

output "ecr_mysql_url" {
  value = aws_ecr_repository.mysql.repository_url
}

output "ec2_public_ip" {
  value = aws_instance.app_server.public_ip
}