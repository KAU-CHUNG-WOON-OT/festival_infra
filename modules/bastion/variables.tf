variable "name_prefix" {
  description = "리소스 이름 접두사"
  type        = string
}

variable "public_subnet_id" {
  description = "Bastion EC2를 배치할 퍼블릭 서브넷 ID"
  type        = string
}

variable "sg_bastion_id" {
  description = "Bastion 보안 그룹 ID"
  type        = string
}

variable "key_name" {
  description = "SSH 접속에 사용할 AWS 키페어 이름"
  type        = string
}
