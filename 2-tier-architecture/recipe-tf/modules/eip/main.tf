resource "aws_eip" "load_balancer" {
  domain   = "vpc"

  tags = var.eip_tags
}