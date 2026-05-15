# ── ALB ───────────────────────────────────────────────────────
resource "aws_lb" "this" {
  name               = "${var.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = { Name = "${var.name_prefix}-alb" }
}

# ── Target Groups ─────────────────────────────────────────────
resource "aws_lb_target_group" "main" {
  name                 = "${var.name_prefix}-main-tg"
  port                 = 8080
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    path                = "/api/v1/health"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    matcher             = "200"
  }

  tags = { Name = "${var.name_prefix}-main-tg" }
}

resource "aws_lb_target_group" "vote" {
  name                 = "${var.name_prefix}-vote-tg"
  port                 = 8081
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 10

  health_check {
    path                = "/api/v1/health"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
    matcher             = "200"
  }

  tags = { Name = "${var.name_prefix}-vote-tg" }
}

resource "aws_lb_target_group" "ticket" {
  name        = "${var.name_prefix}-ticket-query-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    port                = "8000"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}


# ── Listener: HTTP → HTTPS 리다이렉트 ────────────────────────
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ── Listener: HTTPS (기본 fixed-response 404) ─────────────────
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      message_body = "{\"error\":\"Not Found\"}"
      status_code  = "404"
    }
  }
}

# ── Listener Rules ────────────────────────────────────────────

# priority 50: Springdoc Swagger UI / OpenAPI docs → main TG
resource "aws_lb_listener_rule" "swagger" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 50

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    path_pattern {
      values = [
        "/swagger-ui",
        "/swagger-ui/*",
        "/swagger-ui.html",
        "/v3/api-docs",
        "/v3/api-docs/*"
      ]
    }
  }
}

# priority 60: OAuth2 로그인 흐름 → main TG
resource "aws_lb_listener_rule" "oauth2" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 60

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    path_pattern {
      values = [
        "/oauth2/*",
        "/login/oauth2/*",
        "/auth/*"
      ]
    }
  }
}

# priority 100: /api/vote* → vote TG
resource "aws_lb_listener_rule" "vote" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vote.arn
  }

  condition {
    path_pattern {
      values = ["/api/votes*"]
    }
  }
}

# priority 200: /api/* → main TG
resource "aws_lb_listener_rule" "main" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

resource "aws_lb_listener_rule" "ticket" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 70

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ticket.arn
  }

  condition {
    path_pattern {
      values = [
        "/ticket/*",
        "/docs",
        "/openapi.json",
        "/redoc",
        "/health",
      ]
    }
  }
}