output "service_name" {
  description = "ECS 서비스 이름"
  value       = aws_ecs_service.main.name
}

output "task_definition_arn" {
  description = "ECS 태스크 정의 ARN"
  value       = aws_ecs_task_definition.main.arn
}
