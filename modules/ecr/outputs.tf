output "main_repo_url" {
  description = "메인 서비스 ECR 레포지토리 URL"
  value       = aws_ecr_repository.this["main"].repository_url
}

output "vote_repo_url" {
  description = "투표 서비스 ECR 레포지토리 URL"
  value       = aws_ecr_repository.this["vote"].repository_url
}

output "main_repo_arn" {
  description = "메인 서비스 ECR 레포지토리 ARN"
  value       = aws_ecr_repository.this["main"].arn
}

output "vote_repo_arn" {
  description = "투표 서비스 ECR 레포지토리 ARN"
  value       = aws_ecr_repository.this["vote"].arn
}
