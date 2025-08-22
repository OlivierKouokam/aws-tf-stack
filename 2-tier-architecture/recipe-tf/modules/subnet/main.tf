resource "aws_subnet" "my_subnet" {
  vpc_id            = var.vpc_id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.subnet_AZ
  # map_public_ip_on_launch = true
  tags = {
    Name = var.subnet_name
  }
}