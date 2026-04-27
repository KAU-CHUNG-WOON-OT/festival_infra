data "aws_region" "current" {}

# ── SSM: DB 비밀번호 ──────────────────────────────────────────
resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.project_name}/main/db-password"
  type  = "SecureString"
  value = var.db_password

  lifecycle {
    ignore_changes = [value]
  }
}

# ── ECS Task Definition ───────────────────────────────────────
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.name_prefix}-main"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "main"
      image     = "${var.ecr_repository_url}:${var.image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "SERVER_PORT", value = "8080" },
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
          "awslogs-stream-prefix" = "main"
        }
      }

    }
  ])
}

# ── ECS Service ───────────────────────────────────────────────
resource "aws_ecs_service" "main" {
  name            = "${var.name_prefix}-main"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  health_check_grace_period_seconds = 180

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.sg_main_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.tg_main_arn
    container_name   = "main"
    container_port   = 8080
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_controller {
    type = "ECS"
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

# ── Auto Scaling ──────────────────────────────────────────────
resource "aws_appautoscaling_target" "main" {
  min_capacity       = 1
  max_capacity       = 4
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "main_cpu" {
  name               = "${var.name_prefix}-main-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 70
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
