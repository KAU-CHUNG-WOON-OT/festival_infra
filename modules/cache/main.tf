resource "aws_elasticache_subnet_group" "this" {
  name        = "${var.name_prefix}-cache-subnet-group"
  subnet_ids  = var.private_subnet_ids
  description = "Festival ElastiCache subnet group"

  tags = { Name = "${var.name_prefix}-cache-subnet-group" }
}

resource "aws_elasticache_parameter_group" "this" {
  name        = "${var.name_prefix}-redis7"
  family      = "redis7"
  description = "Festival Redis 7 parameters"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }
}

# 단일 노드, 클러스터 모드 비활성화 → aws_elasticache_cluster 사용
resource "aws_elasticache_cluster" "this" {
  cluster_id           = "${var.name_prefix}-redis"
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.t4g.micro"
  num_cache_nodes      = 1
  parameter_group_name = aws_elasticache_parameter_group.this.name
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [var.sg_cache_id]

  snapshot_retention_limit = 1
  snapshot_window          = "03:00-04:00"

  tags = { Name = "${var.name_prefix}-redis" }
}
