
output "private_key" {
  value     = tls_private_key.tls_pk.private_key_pem
  sensitive = true
}

output "public_key" {
  value     = tls_private_key.tls_pk.public_key_openssh
  sensitive = true
}

output "key_name" {
  value = var.key_name
}

#Getting the output from private key is via this command below:
#terraform output -raw private_key