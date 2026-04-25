variable "project_name" {
  description = "모든 리소스 이름 앞에 붙는 프로젝트 식별자"
  type        = string
  default     = "festival"
}

variable "environment" {
  description = "배포 환경 (dev / prod)"
  type        = string
  default     = "prod"

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

variable "alarm_email" {
  description = "CloudWatch 알람 수신 이메일 (빈 문자열이면 구독 생략)"
  type        = string
  default     = ""
}
