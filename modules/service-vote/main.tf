data "aws_region" "current" {}

# ── SSM: DB 비밀번호 ──────────────────────────────────────────
resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.project_name}/vote/db-password"
  type  = "SecureString"
  value = var.db_password

  lifecycle {
    ignore_changes = [value]
  }
}

# ── ECS Task Definition ───────────────────────────────────────
resource "aws_ecs_task_definition" "vote" {
  family                   = "${var.name_prefix}-vote"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "vote"
      image     = "${var.ecr_repository_url}:${var.image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = 8081
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "SERVER_PORT", value = "8081" },
        { name = "DB_URL", value = "jdbc:mysql://${split(":", var.db_endpoint)[0]}:3306/${var.db_name}?serverTimezone=Asia/Seoul&characterEncoding=UTF-8" },
        { name = "DB_USERNAME", value = "admin" },
        { name = "DB_HOST", value = split(":", var.db_endpoint)[0] },
        { name = "DB_PORT", value = "3306" },
        { name = "DB_NAME", value = var.db_name },
        { name = "REDIS_HOST", value = var.redis_host },
        { name = "REDIS_PORT", value = "6379" }
      ]

      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = aws_ssm_parameter.db_password.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group_name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "vote"
        }
      }

    }
  ])
}

# ── ECS Service ───────────────────────────────────────────────
resource "aws_ecs_service" "vote" {
  name            = "${var.name_prefix}-vote"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.vote.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  health_check_grace_period_seconds = 120

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.sg_vote_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.tg_vote_arn
    container_name   = "vote"
    container_port   = 8081
  }

  # desired_count=0 에서 스케줄 스케일아웃 시 새 태스크가 모두 healthy가 된 후
  # 이전 태스크 제거 → 투표 중 다운타임 없음
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = false
    rollback = false
  }

  deployment_controller {
    type = "ECS"
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

# ── Auto Scaling Target ───────────────────────────────────────
resource "aws_appautoscaling_target" "vote" {
  min_capacity       = 1
  max_capacity       = 1
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.vote.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# ── Scheduled Scaling ─────────────────────────────────────────
# 주의: schedule은 UTC 기준입니다.
# KST → UTC 변환 필요 (KST = UTC+9, 예: KST 18:00 → UTC 09:00)
# 아래 cron 표현식은 예시이며, 실제 투표 시간표에 맞춰 반드시 수정하세요.

# scale-out: 운영 시 활성화 (현재 개발 단계 - 1개 고정)
resource "aws_appautoscaling_scheduled_action" "scale_out" {
  name               = "${var.name_prefix}-vote-scale-out"
  resource_id        = aws_appautoscaling_target.vote.resource_id
  scalable_dimension = aws_appautoscaling_target.vote.scalable_dimension
  service_namespace  = aws_appautoscaling_target.vote.service_namespace

  # TODO: KST→UTC 변환 필요, 투표 시간표에 맞춰 수정
  # 예시: KST 17:58 (투표 시작 2분 전) → UTC 08:58
  schedule = "cron(58 8 * * ? *)"

  scalable_target_action {
    min_capacity = 1
    max_capacity = 1
  }
}

# scale-in: 투표 종료 5분 후 → 평시 상태 복귀
resource "aws_appautoscaling_scheduled_action" "scale_in" {
  name               = "${var.name_prefix}-vote-scale-in"
  resource_id        = aws_appautoscaling_target.vote.resource_id
  scalable_dimension = aws_appautoscaling_target.vote.scalable_dimension
  service_namespace  = aws_appautoscaling_target.vote.service_namespace

  # TODO: KST→UTC 변환 필요, 투표 시간표에 맞춰 수정
  # 예시: KST 19:05 (투표 종료 5분 후) → UTC 10:05
  schedule = "cron(5 10 * * ? *)"

  scalable_target_action {
    min_capacity = 1
    max_capacity = 1
  }
}

# ── Target Tracking: ALBRequestCountPerTarget ─────────────────
# 타겟 그룹 당 요청 수 300 초과 시 스케일아웃 (투표 피크 대응)
resource "aws_appautoscaling_policy" "vote_alb_requests" {
  name               = "${var.name_prefix}-vote-alb-request-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.vote.resource_id
  scalable_dimension = aws_appautoscaling_target.vote.scalable_dimension
  service_namespace  = aws_appautoscaling_target.vote.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 300
    scale_out_cooldown = 30 # 투표 트래픽 급증에 빠르게 대응
    scale_in_cooldown  = 60

    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      # format: "<alb-arn-suffix>/<tg-arn-suffix>"
      resource_label = "${var.alb_arn_suffix}/${var.tg_vote_arn_suffix}"
    }
  }
}
