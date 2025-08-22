resource "aws_nat_gateway" "my_nat_gw" {
  allocation_id = var.eip_association_id
  subnet_id     = var.subnet_id

  tags = var.nat_gw_tags

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [var.igw_association]
}