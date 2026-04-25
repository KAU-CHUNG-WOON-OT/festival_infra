# ── SNS ───────────────────────────────────────────────────────
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"

  tags = { Name = "${var.project_name}-alerts" }
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# ── Alarm 1: Main CPU > 80% ───────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "main_cpu" {
  alarm_name          = "${var.name_prefix}-main-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"
  alarm_description   = "메인 서비스 CPU 80% 초과"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.main_service_name
  }
}

# ── Alarm 2: Vote 5xx > 10건 ──────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "vote_5xx" {
  alarm_name          = "${var.name_prefix}-vote-5xx-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"
  alarm_description   = "투표 서비스 5xx 오류 분당 10건 초과"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.tg_vote_arn_suffix
  }
}

# ── Alarm 3: RDS Connections > 50 ────────────────────────────
resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${var.name_prefix}-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 50
  treat_missing_data  = "notBreaching"
  alarm_description   = "RDS 커넥션 수 50 초과"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.db_identifier
  }
}

# ── CloudWatch Dashboard ──────────────────────────────────────
resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # Row 1: ECS CPU / Memory
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ECS CPU Utilization (%)"
          period = 60
          stat   = "Average"
          view   = "timeSeries"
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name, "ServiceName", var.main_service_name, { "label" = "Main" }],
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name, "ServiceName", var.vote_service_name, { "label" = "Vote" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ECS Memory Utilization (%)"
          period = 60
          stat   = "Average"
          view   = "timeSeries"
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ClusterName", var.cluster_name, "ServiceName", var.main_service_name, { "label" = "Main" }],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", var.cluster_name, "ServiceName", var.vote_service_name, { "label" = "Vote" }]
          ]
        }
      },
      # Row 2: ALB 요청수+5xx / 응답시간
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "ALB Request Count / 5xx"
          period = 60
          view   = "timeSeries"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix, { "stat" = "Sum", "label" = "Requests" }],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", var.alb_arn_suffix, { "stat" = "Sum", "label" = "5xx", "color" = "#d62728" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "ALB Target Response Time (p99, sec)"
          period = 60
          stat   = "p99"
          view   = "timeSeries"
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix]
          ]
        }
      },
      # Row 3: RDS 커넥션 / Redis 히트율
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "RDS Database Connections"
          period = 60
          stat   = "Average"
          view   = "timeSeries"
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.db_identifier]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "Redis Cache Hit Rate"
          period = 60
          view   = "timeSeries"
          metrics = [
            ["AWS/ElastiCache", "CacheHits", "CacheClusterId", var.redis_cluster_id, { "stat" = "Sum", "label" = "Hits" }],
            ["AWS/ElastiCache", "CacheMisses", "CacheClusterId", var.redis_cluster_id, { "stat" = "Sum", "label" = "Misses", "color" = "#ff7f0e" }]
          ]
        }
      }
    ]
  })
}
