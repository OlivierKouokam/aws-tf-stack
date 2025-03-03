resource "aws_security_group_rule" "allow_all_ingress" {
  type      = "ingress"
  from_port = 0
  to_port   = 65535
  protocol  = "tcp"
  # cidr_blocks       = [aws_vpc.jenkins_vpc.cidr_block]
  cidr_blocks = var.vpc_cidr_block
  #ipv6_cidr_blocks  = [aws_vpc.jenkins_vpc.ipv6_cidr_block]
  security_group_id = aws_security_group.allow_all_tcp_traffic.id
}

resource "aws_security_group_rule" "allow_all_egress" {
  type     = "egress"
  to_port  = 0
  protocol = "-1"
  //prefix_list_ids   = [aws_vpc_endpoint.my_endpoint.prefix_list_id]
  # cidr_blocks       = [aws_vpc.jenkins_vpc.cidr_block]
  cidr_blocks = var.vpc_cidr_block
  #ipv6_cidr_blocks  = [aws_vpc.jenkins_vpc.ipv6_cidr_block]
  from_port         = 0
  security_group_id = aws_security_group.allow_all_tcp_traffic.id
}

# ...
//resource "aws_vpc_endpoint" "my_endpoint" {
//  # ...
//}

resource "aws_security_group" "allow_all_tcp_traffic" {
  name        = var.sg_name
  description = "Allow all TCP traffic"
  vpc_id      = var.vpc_id
  tags = {
    Name = var.sg_name
  }
  /*
  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh from VPC"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    description = "ssh from VPC"
    from_port = 0
    to_port = 0
    protocol = "ALL"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  */
}
