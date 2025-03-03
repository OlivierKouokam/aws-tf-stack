resource "tls_private_key" "tls_pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.tls_pk.public_key_openssh
}

# Sauvegarder la clé privée localement, pour connexion SSH aux instances EC2
resource "local_file" "private_key" {
  filename        = var.private_key_path
  content         = tls_private_key.tls_pk.private_key_pem
  file_permission = "0600"
}