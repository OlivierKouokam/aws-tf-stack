resource "aws_route_table" "my_route_table" {
  vpc_id = var.vpc_id

  tags = {
    Name = var.route_table_name
  }
}

