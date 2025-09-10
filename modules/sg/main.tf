resource "aws_security_group" "dynamic_sg" {
  name        = var.sg_name
  vpc_id      = var.sg_vpc_id
  tags = var.sg_tags
  description = var.sg_description

  dynamic "ingress" {
    for_each = var.sg_ingress_rules
    content {
      from_port = ingress.value.from_port
      to_port = ingress.value.to_port
      protocol = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = var.sg_cidr_block
  }
}

/*
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
*/

# ...
//resource "aws_vpc_endpoint" "my_endpoint" {
//  # ...
//}
