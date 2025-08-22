output "instance_id" {
  value = aws_instance.this[*].id
}

output "public_ips" {
  value = aws_instance.this[*].public_ip
}

output "private_ip" {
  value = aws_instance.this[0].private_ip
}