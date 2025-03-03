resource "aws_vpc" "stack_vpc" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"

  tags = {
    Name = var.vpc_name
  }
}

# ...
//resource "aws_vpc_endpoint" "my_endpoint" {
//  # ...
//}