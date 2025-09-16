output "aws_sg_name" {
  value = aws_security_group.dynamic_sg.name
}

output "aws_sg_id" {
  value = aws_security_group.dynamic_sg.id
}

#Getting the output from private key is via this command below:
#terraform output -raw private_key