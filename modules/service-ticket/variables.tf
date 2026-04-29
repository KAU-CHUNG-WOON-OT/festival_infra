variable "name_prefix" {
description = "리소스 네이밍 접두사"
type        = string
}

variable "project_name" {
description = "프로젝트 이름"
type        = string
}

variable "cluster_id" {
description = "ECS 클러스터 ID"
type        = string
}

variable "cluster_name" {
description = "ECS 클러스터 이름"
type        = string
}

variable "private_subnet_ids" {
description = "프라이빗 서브넷 ID 목록"
type        = list(string)
}

variable "sg_main_id" {
description = "보안 그룹 ID"
type        = string
}

variable "tg_ticket_arn" {
description = "ALB 타겟 그룹 ARN"
type        = string
}

variable "ecr_repository_url" {
description = "ECR 리포지토리 URL"
type        = string
}

variable "execution_role_arn" {
description = "ECS 태스크 실행 역할 ARN"
type        = string
}

variable "task_role_arn" {
description = "ECS 태스크 역할 ARN"
type        = string
}

variable "log_group_name" {
description = "CloudWatch 로그 그룹 이름"
type        = string
}

variable "db_endpoint" {
description = "RDS 엔드포인트"
type        = string
}

variable "db_name" {
description = "데이터베이스 이름"
type        = string
}

variable "db_password" {
description = "데이터베이스 비밀번호"
type        = string
sensitive   = true
}

variable "jwt_secret" {
description = "JWT 시크릿 키"
type        = string
sensitive   = true
}

variable "image_tag" {
description = "컨테이너 이미지 태그"
type        = string
default     = "latest"
}

variable "desired_count" {
description = "태스크 실행 수"
type        = number
default     = 1
}