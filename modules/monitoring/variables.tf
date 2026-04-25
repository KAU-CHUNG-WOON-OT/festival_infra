variable "name_prefix" {
  description = "리소스 이름 접두사 (project_name-environment)"
  type        = string
}

variable "project_name" {
  description = "SNS 토픽 이름에 사용하는 프로젝트 이름"
  type        = string
}

variable "alarm_email" {
  description = "알람 수신 이메일 (빈 문자열이면 SNS 구독 생략)"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "ECS 클러스터 이름"
  type        = string
}

variable "main_service_name" {
  description = "메인 서비스 ECS 서비스 이름"
  type        = string
}

variable "vote_service_name" {
  description = "투표 서비스 ECS 서비스 이름"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN 접미사 (CloudWatch 지표 dimension)"
  type        = string
}

variable "tg_vote_arn_suffix" {
  description = "투표 서비스 TG ARN 접미사 (5xx 알람용)"
  type        = string
}

variable "db_identifier" {
  description = "RDS 인스턴스 식별자"
  type        = string
}

variable "redis_cluster_id" {
  description = "ElastiCache 클러스터 ID (대시보드 히트율용)"
  type        = string
}
