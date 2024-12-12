output "aws_sg_name" {
  value = aws_security_group.allow_http_https.name
}

output "aws_sg_id" {
  value = aws_security_group.allow_http_https.id
}

#Getting the output from private key is via this command below:
#terraform output -raw private_key