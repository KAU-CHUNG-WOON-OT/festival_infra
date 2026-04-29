locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ── ECR ───────────────────────────────────────────────────────
module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
}

# ── Networking ────────────────────────────────────────────────
module "networking" {
  source = "./modules/networking"

  name_prefix = local.name_prefix
  vpc_cidr    = var.vpc_cidr
}

# ── ALB ───────────────────────────────────────────────────────
module "alb" {
  source = "./modules/alb"

  name_prefix       = local.name_prefix
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  alb_sg_id         = module.networking.sg_alb_id
  certificate_arn   = var.certificate_arn
}

# ── ECS Cluster ───────────────────────────────────────────────
module "ecs_cluster" {
  source = "./modules/ecs-cluster"

  name_prefix  = local.name_prefix
  project_name = var.project_name
}

# ── Database ──────────────────────────────────────────────────
module "database" {
  source = "./modules/database"

  name_prefix             = local.name_prefix
  private_subnet_ids      = module.networking.private_subnet_ids
  sg_db_id                = module.networking.sg_db_id
  db_password             = var.db_password
  backup_retention_period = var.db_backup_retention_period
}

# ── Cache ─────────────────────────────────────────────────────
module "cache" {
  source = "./modules/cache"

  name_prefix        = local.name_prefix
  private_subnet_ids = module.networking.private_subnet_ids
  sg_cache_id        = module.networking.sg_cache_id
}

# ── Main Service ──────────────────────────────────────────────
module "service_main" {
  source = "./modules/service-main"

  name_prefix        = local.name_prefix
  project_name       = var.project_name
  cluster_id         = module.ecs_cluster.cluster_id
  cluster_name       = module.ecs_cluster.cluster_name
  private_subnet_ids = module.networking.private_subnet_ids
  sg_main_id         = module.networking.sg_main_id
  tg_main_arn        = module.alb.tg_main_arn
  ecr_repository_url = module.ecr.main_repo_url
  execution_role_arn = module.ecs_cluster.execution_role_arn
  task_role_arn      = module.ecs_cluster.task_role_arn
  log_group_name     = module.ecs_cluster.log_group_main_name
  db_endpoint        = module.database.db_endpoint
  db_name            = module.database.db_name
  db_password        = var.db_password
  redis_host         = module.cache.redis_endpoint
}

# ── Vote Service ──────────────────────────────────────────────
module "service_vote" {
  source = "./modules/service-vote"

  name_prefix        = local.name_prefix
  project_name       = var.project_name
  cluster_id         = module.ecs_cluster.cluster_id
  cluster_name       = module.ecs_cluster.cluster_name
  private_subnet_ids = module.networking.private_subnet_ids
  sg_vote_id         = module.networking.sg_vote_id
  tg_vote_arn        = module.alb.tg_vote_arn
  alb_arn_suffix     = module.alb.alb_arn_suffix
  tg_vote_arn_suffix = module.alb.tg_vote_arn_suffix
  ecr_repository_url = module.ecr.main_repo_url
  execution_role_arn = module.ecs_cluster.execution_role_arn
  task_role_arn      = module.ecs_cluster.task_role_arn
  log_group_name     = module.ecs_cluster.log_group_vote_name
  db_endpoint        = module.database.db_endpoint
  db_name            = module.database.db_name
  db_password        = var.db_password
  redis_host         = module.cache.redis_endpoint
}

# ── Ticket Query Service ──────────────────────────────────────
module "service_ticket" {
  source = "./modules/service-ticket"

  name_prefix        = local.name_prefix
  project_name       = var.project_name
  cluster_id         = module.ecs_cluster.cluster_id
  cluster_name       = module.ecs_cluster.cluster_name
  private_subnet_ids = module.networking.private_subnet_ids
  sg_ticket_id       = module.networking.sg_ticket_id
  tg_ticket_arn      = module.alb.tg_ticket_arn
  ecr_repository_url = module.ecr.ticket_query_repo_url
  execution_role_arn = module.ecs_cluster.execution_role_arn
  task_role_arn      = module.ecs_cluster.task_role_arn
  log_group_name     = module.ecs_cluster.log_group_ticket_query_name
  db_endpoint        = module.database.db_endpoint
  db_name            = module.database.db_name
  db_password        = var.db_password
  jwt_secret         = var.jwt_secret
}

# ── Bastion ───────────────────────────────────────────────────
module "bastion" {
  source = "./modules/bastion"

  name_prefix      = local.name_prefix
  public_subnet_id = module.networking.public_subnet_ids[0]
  sg_bastion_id    = module.networking.sg_bastion_id
  key_name         = var.bastion_key_name
}

# ── Monitoring ────────────────────────────────────────────────
module "monitoring" {
  source = "./modules/monitoring"

  name_prefix        = local.name_prefix
  project_name       = var.project_name
  alarm_email        = var.alarm_email
  cluster_name       = module.ecs_cluster.cluster_name
  main_service_name  = module.service_main.service_name
  vote_service_name  = module.service_vote.service_name
  alb_arn_suffix     = module.alb.alb_arn_suffix
  tg_vote_arn_suffix = module.alb.tg_vote_arn_suffix
  db_identifier      = module.database.db_instance_id
  redis_cluster_id   = module.cache.redis_cluster_id
}
