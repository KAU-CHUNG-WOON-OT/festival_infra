output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "퍼블릭 서브넷 ID 목록 [2a, 2c]"
  value       = [aws_subnet.public_2a.id, aws_subnet.public_2c.id]
}

output "private_subnet_ids" {
  description = "프라이빗 서브넷 ID 목록 [2a, 2c]"
  value       = [aws_subnet.private_2a.id, aws_subnet.private_2c.id]
}

output "sg_alb_id" {
  description = "ALB 보안 그룹 ID"
  value       = aws_security_group.alb.id
}

output "sg_main_id" {
  description = "메인 서비스 보안 그룹 ID"
  value       = aws_security_group.main.id
}

output "sg_vote_id" {
  description = "투표 서비스 보안 그룹 ID"
  value       = aws_security_group.vote.id
}

output "sg_ticket_id" {
  description = "팔찌 서비스 보안 그룹 ID"
  value = aws_security_group.ticket.id
}

output "sg_db_id" {
  description = "DB 보안 그룹 ID"
  value       = aws_security_group.db.id
}

output "sg_cache_id" {
  description = "Cache 보안 그룹 ID"
  value       = aws_security_group.cache.id
}

output "sg_bastion_id" {
  description = "Bastion 보안 그룹 ID"
  value       = aws_security_group.bastion.id
}
