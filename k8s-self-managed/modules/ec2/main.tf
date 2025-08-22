resource "aws_instance" "this" {
  count                       = var.worker_number
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.subnets[count.index % length(var.subnets)]
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = true
  iam_instance_profile        = var.iam_instance_profile
  root_block_device {
    volume_type           = var.volume_type
    volume_size           = var.volume_size
    delete_on_termination = true
  }
  tags = {
    Name = "k8s_${var.instance_role}_${var.worker_number}"
  }
}


