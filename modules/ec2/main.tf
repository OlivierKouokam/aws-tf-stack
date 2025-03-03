data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    #values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "webserver" {
  subnet_id       = var.subnet_id
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  key_name        = var.key_name
  # security_groups = var.security_groups
  vpc_security_group_ids = var.security_group_ids
  # associate_public_ip_address = true
  tags            = var.aws_common_tag

  user_data = file(var.user_data_path)
  # "sudo amazon-linux-extras install -y nginx1.12",
  /*
  provisioner "remote-exec" {
    inline = [ 
      "sudo apt update -y",
      "sudo apt install -y nginx"
    ]

    connection {
      type = "ssh"
      user = "ubuntu"
      # private_key = file("../.secrets/devops-olivier.pem")
      private_key = var.private_key
      host = self.public_ip
    }
  }
*/
}
