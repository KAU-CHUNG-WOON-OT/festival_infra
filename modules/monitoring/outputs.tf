output "sns_topic_arn" {
  description = "알람 SNS 토픽 ARN"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_name" {
  description = "CloudWatch 대시보드 이름"
  value       = aws_cloudwatch_dashboard.this.dashboard_name
}
