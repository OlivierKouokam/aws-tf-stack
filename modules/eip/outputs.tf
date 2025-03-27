output "eip_id" {
  value = aws_eip.load_balancer.id
}

output "public_ip" {
  value = aws_eip.load_balancer.public_ip
}

output "public_dns" {
  value = aws_eip.load_balancer.public_dns
}