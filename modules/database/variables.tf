variable "name_prefix" {
  description = "리소스 이름 접두사 (project_name-environment)"
  type        = string
}

variable "private_subnet_ids" {
  description = "RDS를 배치할 프라이빗 서브넷 ID 목록"
  type        = list(string)
}

variable "sg_db_id" {
  description = "RDS에 적용할 보안 그룹 ID"
  type        = string
}

variable "db_password" {
  description = "RDS 마스터 비밀번호"
  type        = string
  sensitive   = true
}

variable "backup_retention_period" {
  description = "RDS 자동 백업 보관 기간(일)"
  type        = number
}
