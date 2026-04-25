variable "name_prefix" {
  description = "리소스 이름 접두사 (project_name-environment)"
  type        = string
}

variable "vpc_id" {
  description = "ALB 타겟 그룹을 생성할 VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "ALB를 배치할 퍼블릭 서브넷 ID 목록"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "ALB에 적용할 보안 그룹 ID"
  type        = string
}

variable "certificate_arn" {
  description = "HTTPS 리스너에 적용할 ACM 인증서 ARN"
  type        = string
}
