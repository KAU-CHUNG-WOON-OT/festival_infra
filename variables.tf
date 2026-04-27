variable "project_name" {
  description = "모든 리소스 이름 앞에 붙는 프로젝트 식별자"
  type        = string
  default     = "festival"
}

variable "environment" {
  description = "배포 환경 (dev / prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment 는 'dev' 또는 'prod' 여야 합니다."
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}

variable "domain_name" {
  description = "축제 사이트 도메인 (예: festival.example.com)"
  type        = string
}

variable "certificate_arn" {
  description = "HTTPS 적용에 사용할 ACM 인증서 ARN"
  type        = string
}

variable "db_password" {
  description = "RDS 데이터베이스 마스터 비밀번호"
  type        = string
  sensitive   = true
}

variable "db_backup_retention_period" {
  description = "RDS 자동 백업 보관 기간(일). dev/free tier에서는 0으로 비활성화 가능"
  type        = number
  default     = 7

  validation {
    condition     = var.db_backup_retention_period >= 0 && var.db_backup_retention_period <= 35
    error_message = "db_backup_retention_period 는 0 이상 35 이하이어야 합니다."
  }
}

variable "alarm_email" {
  description = "CloudWatch 알람 수신 이메일 (빈 문자열이면 구독 생략)"
  type        = string
  default     = ""
}
