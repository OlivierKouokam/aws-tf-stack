module "minishift_vpc" {
  source         = "../modules/vpc"
  vpc_name       = "minishift-vpc"
  vpc_cidr_block = "10.1.0.0/16"
}

module "public_subnet" {
  source            = "../modules/subnet"
  vpc_id            = module.minishift_vpc.stack_vpc_id
  subnet_cidr_block = "10.1.1.0/24"
  subnet_name       = "minishift_public_subnet"
  subnet_AZ         = var.minishift_AZ
}

module "minishift_igw" {
  source   = "../modules/igw"
  igw_name = "minishift_igw"
  vpc_id   = module.minishift_vpc.stack_vpc_id
}

module "minishift_route_table" {
  source           = "../modules/route_table"
  vpc_id           = module.minishift_vpc.stack_vpc_id
  route_table_name = "minishift_route_table"
}

resource "aws_route" "internet_access" {
  route_table_id         = module.minishift_route_table.route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.minishift_igw.igw_id
}

resource "aws_route_table_association" "public_subnet_to_minishift_igw" {
  subnet_id      = module.public_subnet.subnet_id
  route_table_id = module.minishift_route_table.route_table_id
}

module "sg" {
  source         = "../modules/sg"
  sg_name        = "minishift-sg"
  vpc_id         = module.minishift_vpc.stack_vpc_id
  vpc_cidr_block = ["0.0.0.0/0"]
}

module "keypair" {
  source           = "../modules/keypair"
  key_name         = "devops-minishift"
  private_key_path = "../.secrets/${module.keypair.key_name}.pem"
}

module "minishift_ec2" {
  depends_on    = [module.sg, module.keypair]
  source        = "../modules/ec2"
  subnet_id     = module.public_subnet.subnet_id
  instance_type = "t3.medium"
  aws_common_tag = {
    Name = "minishift-ec2"
  }
  key_name           = module.keypair.key_name
  security_group_ids = [module.sg.aws_sg_id]
  # security_groups = [module.sg.aws_sg_name]
  private_key    = module.keypair.private_key
  user_data_path = "../scripts/userdata_minishift.sh"
}

module "openshift_ec2" {
  depends_on    = [module.sg, module.keypair]
  source        = "../modules/ec2"
  subnet_id     = module.public_subnet.subnet_id
  instance_type = "t3.medium"
  aws_common_tag = {
    Name = "openshift-ec2"
  }
  key_name           = module.keypair.key_name
  security_group_ids = [module.sg.aws_sg_id]
  # security_groups = [module.sg.aws_sg_name]
  private_key    = module.keypair.private_key
  user_data_path = "../scripts/userdata_minishift.sh"
}

module "production_ec2" {
  depends_on    = [module.sg, module.keypair]
  source        = "../modules/ec2"
  subnet_id     = module.public_subnet.subnet_id
  instance_type = "t3.medium"
  aws_common_tag = {
    Name = "production-ec2"
  }
  key_name           = module.keypair.key_name
  security_group_ids = [module.sg.aws_sg_id]
  # security_groups = [module.sg.aws_sg_name]
  private_key    = module.keypair.private_key
  user_data_path = "../scripts/userdata_worker.sh"
}

module "minishift_eip" {
  depends_on = [ module.minishift_ec2 ]
  source = "../modules/eip"
  eip_tags = {
    Name = "minishift_eip"
  }
}

module "minishift_ebs" {
  source = "../modules/ebs"
  AZ     = var.minishift_AZ
  size   = 20
  ebs_tag = {
    Name = "minishift_ebs"
  }
}

resource "aws_eip_association" "minishift_eip_assoc" {
  instance_id   = module.minishift_ec2.ec2_instance_id
  allocation_id = module.minishift_eip.eip_id
}

resource "aws_volume_attachment" "minishift_ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = module.minishift_ebs.aws_ebs_volume_id
  instance_id = module.minishift_ec2.ec2_instance_id
}

module "openshift_eip" {
  depends_on = [ module.openshift_ec2]
  source = "../modules/eip"
  eip_tags = {
    Name = "openshift_eip"
  }
}

module "openshift_ebs" {
  source = "../modules/ebs"
  AZ     = var.minishift_AZ
  size   = 20
  ebs_tag = {
    Name = "openshift_ebs"
  }
}

resource "aws_eip_association" "openshift_eip_assoc" {
  instance_id   = module.openshift_ec2.ec2_instance_id
  allocation_id = module.openshift_eip.eip_id
}

resource "aws_volume_attachment" "openshift_ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = module.openshift_ebs.aws_ebs_volume_id
  instance_id = module.openshift_ec2.ec2_instance_id
}

module "production_eip" {
  depends_on = [ module.openshift_ec2]
  source = "../modules/eip"
  eip_tags = {
    Name = "production_eip"
  }
}

module "production_ebs" {
  source = "../modules/ebs"
  AZ     = var.minishift_AZ
  size   = 20
  ebs_tag = {
    Name = "production_ebs"
  }
}

resource "aws_eip_association" "production_eip_assoc" {
  instance_id   = module.production_ec2.ec2_instance_id
  allocation_id = module.production_eip.eip_id
}

resource "aws_volume_attachment" "production_ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = module.production_ebs.aws_ebs_volume_id
  instance_id = module.production_ec2.ec2_instance_id
}

resource "null_resource" "output_metadatas" {
  depends_on = [module.minishift_ec2, module.openshift_ec2, module.production_ec2]
  
  provisioner "local-exec" {
  #   command = <<EOT
  #     echo minishift-ec2-IP-DNS
  #     echo PUBLIC_IP: ${module.minishift_ec2.public_ip} - PUBLIC_DNS: ${module.minishift_ec2.public_dns}  > minishift_ec2.txt
  #   EOT
  command = "echo minishift PUBLIC_IP: ${module.minishift_eip.public_ip} - minishift PUBLIC_DNS: ${module.minishift_eip.public_dns}  >> minishift_ec2.txt"
  }

  provisioner "local-exec" {
    command = "echo openshift PUBLIC_IP: ${module.openshift_eip.public_ip} - openshift PUBLIC_DNS: ${module.openshift_eip.public_dns}  >> minishift_ec2.txt"
  }

  provisioner "local-exec" {
    command = "echo Production PUBLIC_IP: ${module.production_eip.public_ip} - Production PUBLIC_DNS: ${module.production_eip.public_dns}  >> minishift_ec2.txt"
  }
}