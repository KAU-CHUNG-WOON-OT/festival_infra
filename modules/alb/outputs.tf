output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "ALB DNS 이름 (Route53 ALIAS 레코드에 사용)"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "ALB 호스팅 영역 ID"
  value       = aws_lb.this.zone_id
}

output "alb_arn_suffix" {
  description = "CloudWatch 지표용 ALB ARN 접미사"
  value       = aws_lb.this.arn_suffix
}

output "tg_main_arn" {
  description = "메인 서비스 타겟 그룹 ARN"
  value       = aws_lb_target_group.main.arn
}

output "tg_vote_arn" {
  description = "투표 서비스 타겟 그룹 ARN"
  value       = aws_lb_target_group.vote.arn
}

output "tg_main_arn_suffix" {
  description = "CloudWatch 지표용 메인 TG ARN 접미사"
  value       = aws_lb_target_group.main.arn_suffix
}

output "tg_vote_arn_suffix" {
  description = "CloudWatch 지표용 투표 TG ARN 접미사"
  value       = aws_lb_target_group.vote.arn_suffix
}
