# ── ALB ───────────────────────────────────────────────────────
output "alb_dns_name" {
  description = "ALB DNS 이름 (Route53 ALIAS 레코드에 사용)"
  value       = module.alb.alb_dns_name
}

# ── ECS ───────────────────────────────────────────────────────
output "ecs_cluster_name" {
  description = "ECS 클러스터 이름"
  value       = module.ecs_cluster.cluster_name
}

# ── ECR ───────────────────────────────────────────────────────
output "ecr_main_repo_url" {
  description = "메인 서비스 ECR 레포지토리 URL"
  value       = module.ecr.main_repo_url
}

output "ecr_vote_repo_url" {
  description = "투표 서비스 ECR 레포지토리 URL"
  value       = module.ecr.vote_repo_url
}

# ── Database ──────────────────────────────────────────────────
output "db_endpoint" {
  description = "RDS 엔드포인트 (host:port)"
  value       = module.database.db_endpoint
  sensitive   = true
}

# ── Cache ─────────────────────────────────────────────────────
output "redis_endpoint" {
  description = "ElastiCache Redis 엔드포인트"
  value       = module.cache.redis_endpoint
  sensitive   = true
}

# ── Bastion ───────────────────────────────────────────────────
output "bastion_public_ip" {
  description = "Bastion EC2 퍼블릭 IP (IntelliJ SSH 터널 주소)"
  value       = module.bastion.public_ip
}
