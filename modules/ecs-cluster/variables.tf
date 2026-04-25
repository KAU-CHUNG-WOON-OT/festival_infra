variable "name_prefix" {
  description = "리소스 이름 접두사 (project_name-environment)"
  type        = string
}

variable "project_name" {
  description = "로그 그룹 이름 및 SSM 파라미터 경로에 사용되는 프로젝트 이름"
  type        = string
}
