output "public_ip" {
  value = aws_instance.webserver.public_ip
}

output "public_dns" {
  value = aws_instance.webserver.public_dns
}
#Getting the output from private key is via this command below:
#terraform output -raw private_key

output "ec2_instance_id" {
  value = aws_instance.webserver.id
}

output "private_ip" {
  value = aws_instance.webserver.private_ip
}

output "private_dns" {
  value = aws_instance.webserver.private_dns
}