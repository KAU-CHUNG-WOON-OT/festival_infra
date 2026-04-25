variable "name_prefix" {
  description = "리소스 이름 접두사 (project_name-environment)"
  type        = string
}

variable "private_subnet_ids" {
  description = "ElastiCache를 배치할 프라이빗 서브넷 ID 목록"
  type        = list(string)
}

variable "sg_cache_id" {
  description = "ElastiCache에 적용할 보안 그룹 ID"
  type        = string
}
