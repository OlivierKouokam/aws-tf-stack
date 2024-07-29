resource "aws_vpc" "jenkins_vpc" {
  cidr_block       = "172.32.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = var.vpc_name
  }
}

# ...
//resource "aws_vpc_endpoint" "my_endpoint" {
//  # ...
//}