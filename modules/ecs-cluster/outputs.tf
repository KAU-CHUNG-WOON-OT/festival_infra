output "cluster_id" {
  description = "ECS 클러스터 ID"
  value       = aws_ecs_cluster.this.id
}

output "cluster_name" {
  description = "ECS 클러스터 이름"
  value       = aws_ecs_cluster.this.name
}

output "execution_role_arn" {
  description = "ECS 태스크 실행 역할 ARN"
  value       = aws_iam_role.execution.arn
}

output "task_role_arn" {
  description = "ECS 태스크 역할 ARN"
  value       = aws_iam_role.task.arn
}

output "log_group_main_name" {
  description = "메인 서비스 CloudWatch 로그 그룹 이름"
  value       = aws_cloudwatch_log_group.main.name
}

output "log_group_vote_name" {
  description = "투표 서비스 CloudWatch 로그 그룹 이름"
  value       = aws_cloudwatch_log_group.vote.name
}
