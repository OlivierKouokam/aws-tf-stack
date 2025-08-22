output "nat_gateway_id" {
  description = "ID de la NAT Gateway"
  value       = aws_nat_gateway.my_nat_gw.id
}

output "nat_gateway_ip" {
  description = "Public IP de la NAT Gateway"
  value       = aws_nat_gateway.my_nat_gw.public_ip
}
