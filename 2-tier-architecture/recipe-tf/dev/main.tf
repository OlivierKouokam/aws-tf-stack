module "recipe_vpc" {
  source         = "../modules/vpc"
  vpc_name       = "recipe-vpc"
  vpc_cidr_block = "10.1.0.0/16"
}

module "public_subnet" {
  source            = "../modules/subnet"
  vpc_id            = module.recipe_vpc.stack_vpc_id
  subnet_cidr_block = "10.1.1.0/24"
  subnet_name       = "recipe_public_subnet"
  subnet_AZ         = var.recipe_AZ
}

module "private_subnet" {
  source            = "../modules/subnet"
  vpc_id            = module.recipe_vpc.stack_vpc_id
  subnet_cidr_block = "10.1.2.0/24"
  subnet_name       = "recipe_private_subnet"
  subnet_AZ         = var.recipe_AZ
}

module "recipe_igw" {
  source   = "../modules/igw"
  igw_name = "recipe_igw"
  vpc_id   = module.recipe_vpc.stack_vpc_id
}

module "recipe_nat_eip" {
  source = "../modules/eip"
  eip_tags = {
    Name = "recipe_nat_eip"
  }
}

module "recipe_nat_gw" {
  source = "../modules/nat_gw"
  eip_association_id = module.recipe_nat_eip.eip_id
  subnet_id = module.public_subnet.subnet_id
  igw_association = module.recipe_igw
}

module "recipe_nat_route_table" {
  source           = "../modules/route_table"
  vpc_id           = module.recipe_vpc.stack_vpc_id
  route_table_name = "recipe_nat_route_table"
}

resource "aws_route" "internet_natgw_access" {
  route_table_id         = module.recipe_nat_route_table.route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.recipe_nat_gw.nat_gateway_id
}

resource "aws_route_table_association" "private_subnet_to_natgw" {
  subnet_id      = module.private_subnet.subnet_id
  route_table_id = module.recipe_nat_route_table.route_table_id
}

module "recipe_igw_route_table" {
  source           = "../modules/route_table"
  vpc_id           = module.recipe_vpc.stack_vpc_id
  route_table_name = "recipe_igw_route_table"
}

resource "aws_route" "internet_access" {
  route_table_id         = module.recipe_igw_route_table.route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.recipe_igw.igw_id
}

resource "aws_route_table_association" "public_subnet_to_recipe_igw" {
  subnet_id      = module.public_subnet.subnet_id
  route_table_id = module.recipe_igw_route_table.route_table_id
}

module "sg" {
  source         = "../modules/sg"
  sg_name        = "recipe-sg"
  vpc_id         = module.recipe_vpc.stack_vpc_id
  vpc_cidr_block = ["0.0.0.0/0"]
}

module "keypair" {
  source           = "../modules/keypair"
  key_name         = "devops-recipe"
  private_key_path = "../.secrets/${module.keypair.key_name}.pem"
}

module "recipe_app_ec2" {
  depends_on    = [module.sg, module.keypair]
  source        = "../modules/ec2"
  subnet_id     = module.public_subnet.subnet_id
  instance_type = "t3.medium"
  aws_common_tag = {
    Name = "recipe_app_ec2"
  }
  key_name           = module.keypair.key_name
  security_group_ids = [module.sg.aws_sg_id]
  # security_groups = [module.sg.aws_sg_name]
  private_key    = module.keypair.private_key
  user_data_path = "../scripts/userdata_docker.sh"
}

module "recipe_api_ec2" {
  depends_on    = [module.sg, module.keypair]
  source        = "../modules/ec2"
  subnet_id     = module.private_subnet.subnet_id
  instance_type = "t3.medium"
  aws_common_tag = {
    Name = "recipe_api_ec2"
  }
  key_name           = module.keypair.key_name
  security_group_ids = [module.sg.aws_sg_id]
  # security_groups = [module.sg.aws_sg_name]
  private_key    = module.keypair.private_key
  user_data_path = "../scripts/userdata_docker.sh"
}

module "recipe_app_eip" {
  depends_on = [ module.recipe_app_ec2 ]
  source = "../modules/eip"
  eip_tags = {
    Name = "recipe_app_eip"
  }
}

module "recipe_app_ebs" {
  source = "../modules/ebs"
  AZ     = var.recipe_AZ
  size   = 20
  ebs_tag = {
    Name = "recipe_app_ebs"
  }
}

resource "aws_eip_association" "recipe_app_eip_assoc" {
  instance_id   = module.recipe_app_ec2.ec2_instance_id
  allocation_id = module.recipe_app_eip.eip_id
}

resource "aws_volume_attachment" "recipe_app_ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = module.recipe_app_ebs.aws_ebs_volume_id
  instance_id = module.recipe_app_ec2.ec2_instance_id
}

module "recipe_api_ebs" {
  source = "../modules/ebs"
  AZ     = var.recipe_AZ
  size   = 20
  ebs_tag = {
    Name = "recipe_api_ebs"
  }
}

resource "aws_volume_attachment" "recipe_api_att" {
  device_name = "/dev/sdh"
  volume_id   = module.recipe_api_ebs.aws_ebs_volume_id
  instance_id = module.recipe_api_ec2.ec2_instance_id
}

resource "null_resource" "output_metadata" {
  depends_on = [module.recipe_app_eip, module.recipe_api_ec2]
  
  provisioner "local-exec" {
    command = "echo recipe_app PUBLIC_IP: ${module.recipe_app_eip.public_ip} - recipe_app PUBLIC_DNS: ${module.recipe_app_eip.public_dns}  >> recipe_ec2.txt"
  }

  provisioner "local-exec" {
    command = "echo recipe_api PUBLIC_IP: ${module.recipe_api_ec2.private_ip} - recipe_api PUBLIC_DNS: ${module.recipe_api_ec2.private_dns}  >> recipe_ec2.txt"
  }
}
