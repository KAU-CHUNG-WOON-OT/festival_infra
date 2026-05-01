# ── SSM: JWT Secret ───────────────────────────────────────────
resource "aws_ssm_parameter" "jwt_secret" {
  name  = "/${var.project_name}/ticket-query/jwt-secret"
  type  = "SecureString"
  value = var.jwt_secret

  lifecycle {
    ignore_changes = [value]
  }
}

# ── SSM: DB Password ─────────────────────────────────────────
resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.project_name}/ticket-query/db-password"
  type  = "SecureString"
  value = var.db_password

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "docs_password" {
  name  = "/${var.project_name}/ticket-query/docs-password"
  type  = "SecureString"
  value = var.docs_password
  lifecycle {
    ignore_changes = [value]
  }
}

# ── ECS Task Definition ──────────────────────────────────────
resource "aws_ecs_task_definition" "ticket_query" {
  family                   = "${var.name_prefix}-ticket-query"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "ticket-query"
      image     = "${var.ecr_repository_url}:${var.image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "AWS_REGION",   value = "ap-northeast-2" },
        { name = "TICKET_TABLE", value = "festival-ticketing-ticket" },
        { name = "RDS_HOST",     value = split(":", var.db_endpoint)[0] },
        { name = "RDS_PORT",     value = "3306" },
        { name = "RDS_USER",     value = "admin" },
        { name = "RDS_DATABASE", value = var.db_name },
        { name = "DOCS_USERNAME", value = var.docs_username },
      ]

      secrets = [
        {
          name      = "JWT_SECRET"
          valueFrom = aws_ssm_parameter.jwt_secret.arn
        },
        {
          name      = "RDS_PASSWORD"
          valueFrom = aws_ssm_parameter.db_password.arn
        },
        {
          name      = "DOCS_PASSWORD"
          valueFrom = aws_ssm_parameter.docs_password.arn
        }

      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group_name
          "awslogs-region"        = "ap-northeast-2"
          "awslogs-stream-prefix" = "ticket-query"
        }
      }
    }
  ])
}




# ── ECS Service ───────────────────────────────────────────────
resource "aws_ecs_service" "ticket_query" {
  name            = "${var.name_prefix}-ticket-query"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.ticket_query.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  health_check_grace_period_seconds = 180

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups = [var.sg_ticket_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.tg_ticket_arn
    container_name   = "ticket-query"
    container_port   = 8000
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }
}