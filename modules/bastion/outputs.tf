output "public_ip" {
  description = "Bastion EC2 고정 퍼블릭 IP (IntelliJ SSH 터널에 입력)"
  value       = aws_eip.bastion.public_ip
}
