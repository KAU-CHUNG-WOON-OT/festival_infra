output "db_endpoint" {
  description = "RDS 엔드포인트 (host:port)"
  value       = aws_db_instance.this.endpoint
  sensitive   = true
}

output "db_name" {
  description = "데이터베이스 이름"
  value       = aws_db_instance.this.db_name
}

output "db_port" {
  description = "RDS 포트"
  value       = aws_db_instance.this.port
}

output "db_instance_id" {
  description = "RDS 인스턴스 식별자"
  value       = aws_db_instance.this.identifier
}
