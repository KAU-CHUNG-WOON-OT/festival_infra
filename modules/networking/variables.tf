variable "name_prefix" {
  description = "리소스 이름 접두사 (project_name-environment)"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
}
