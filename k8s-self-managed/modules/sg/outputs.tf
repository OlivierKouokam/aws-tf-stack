output "sg_id" {
  description = "ID du security group"
  value       = aws_security_group.this.id
}