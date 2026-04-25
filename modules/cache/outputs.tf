output "redis_endpoint" {
  description = "Redis 엔드포인트 호스트명"
  value       = aws_elasticache_cluster.this.cache_nodes[0].address
  sensitive   = true
}

output "redis_port" {
  description = "Redis 포트"
  value       = aws_elasticache_cluster.this.port
}

output "redis_cluster_id" {
  description = "ElastiCache 클러스터 ID"
  value       = aws_elasticache_cluster.this.cluster_id
}
