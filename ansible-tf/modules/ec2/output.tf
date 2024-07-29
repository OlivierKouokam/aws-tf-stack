output "public_ip" {
  value = aws_instance.webserver.public_ip
}

output "public_dns" {
    value = aws_instance.webserver.public_dns
}
#Getting the output from private key is via this command below:
#terraform output -raw private_key