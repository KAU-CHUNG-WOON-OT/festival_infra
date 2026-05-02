variable "name_prefix" {
  description = "리소스 이름 접두사 (project_name-environment)"
  type        = string
}

variable "project_name" {
  description = "SSM 파라미터 경로에 사용하는 프로젝트 이름"
  type        = string
}

# ── 클러스터 ──────────────────────────────────────────────────
variable "cluster_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

# ── 네트워크 ──────────────────────────────────────────────────
variable "private_subnet_ids" {
  type = list(string)
}

variable "sg_vote_id" {
  description = "투표 서비스 ECS 태스크 보안 그룹 ID"
  type        = string
}

# ── ALB ───────────────────────────────────────────────────────
variable "tg_vote_arn" {
  description = "투표 서비스 ALB 타겟 그룹 ARN"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALBRequestCountPerTarget 지표 resource_label 구성용 ALB ARN suffix"
  type        = string
}

variable "tg_vote_arn_suffix" {
  description = "ALBRequestCountPerTarget 지표 resource_label 구성용 TG ARN suffix"
  type        = string
}

# ── ECR ───────────────────────────────────────────────────────
variable "ecr_repository_url" {
  description = "투표 서비스 ECR 이미지 URL (태그 제외)"
  type        = string
}

variable "image_tag" {
  type    = string
  default = "latest"
}

# ── IAM / Logging (ecs-cluster 모듈에서 수령) ─────────────────
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

# ── DB ────────────────────────────────────────────────────────
variable "db_endpoint" {
  description = "RDS 엔드포인트 (host:port)"
  type        = string
  sensitive   = true
}

variable "db_name" {
  type = string
}

variable "db_password" {
  description = "SSM SecureString 저장용 DB 비밀번호"
  type        = string
  sensitive   = true
}

# ── Cache ─────────────────────────────────────────────────────
variable "redis_host" {
  description = "Redis 호스트명"
  type        = string
  sensitive   = true
}

# ── 스케일링 ──────────────────────────────────────────────────
variable "desired_count" {
  description = "초기 ECS 태스크 수"
  type        = number
  default     = 1
}
