# terraform {
#   backend "s3" {
#     region     = "us-east-1"
#     # access_key = "YOUR-ACCESS-KEY"
#     # secret_key = "YOUR-SECRET-KEY"
#     shared_credentials_files = ["../.secrets/credentials"]
#     bucket = "backend-eazyastuces"
#     key = "eazy-astuce.tfstate"
#   }
# }

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.60.0"
    }
  }

  required_version = "1.9.4"
}

provider "aws" {
  region                   = var.terraform_region
  shared_credentials_files = ["../.secrets/credentials"]
  profile                  = "stack"
}

module "vpc" {
  source         = "../modules/vpc"
  vpc_name       = "terraform-vpc"
  vpc_cidr_block = "10.2.0.0/16"
}

module "public_subnet" {
  source            = "../modules/subnet"
  vpc_id            = module.vpc.stack_vpc_id
  subnet_cidr_block = "10.2.1.0/24"
  subnet_name       = "terraform_public_subnet"
  subnet_AZ         = var.terraform_AZ
}

module "terraform_igw" {
  source   = "../modules/igw"
  igw_name = "terraform_igw"
  vpc_id   = module.vpc.stack_vpc_id
}

module "terraform_route_table" {
  source           = "../modules/route_table"
  vpc_id           = module.vpc.stack_vpc_id
  route_table_name = "terraform_route_table"
}

resource "aws_route" "internet_access" {
  route_table_id         = module.terraform_route_table.route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.terraform_igw.igw_id
}

resource "aws_route_table_association" "public_subnet_to_terraform_igw" {
  subnet_id      = module.public_subnet.subnet_id
  route_table_id = module.terraform_route_table.route_table_id
}

module "sg" {
  source         = "../modules/sg"
  sg_name        = "terraform-sg"
  sg_vpc_id         = module.vpc.stack_vpc_id
  sg_cidr_block = var.tf_cidr_blocks
  sg_ingress_rules = [
    { from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = var.tf_cidr_blocks, description = "allow SSH inbound traffic" },
    { from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = var.tf_cidr_blocks, description = "allow HTTP inbound traffic" },
    { from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = var.tf_cidr_blocks, description = "allow HTTPS inbound traffic" },
    { from_port = 8080, to_port = 8080, protocol = "tcp", cidr_blocks = var.tf_cidr_blocks, description = "allow jenkins port inbound traffic" },
    { protocol = -1, cidr_blocks = var.tf_cidr_blocks, description = "allow all traffic" }
  ]
}

module "keypair" {
  source           = "../modules/keypair"
  key_name         = "devops-terraform"
  private_key_path = "../.secrets/${module.keypair.key_name}.pem"
}

module "terraform_ec2" {
  depends_on = [
    module.sg, module.keypair,
    resource.aws_route_table_association.public_subnet_to_terraform_igw
  ]
  source        = "../modules/ec2"
  subnet_id     = module.public_subnet.subnet_id
  instance_type = "t3.micro"
  aws_common_tag = {
    Name = "terraform-ec2"

  }
  key_name           = module.keypair.key_name
  security_group_ids = [module.sg.aws_sg_id]
  private_key        = module.keypair.private_key
  user_data_path     = "../scripts/userdata_terraform.sh"
}

module "terraform_eip" {
  depends_on = [module.terraform_ec2]
  source     = "../modules/eip"
  eip_tags = {
    Name = "terraform_eip"
  }
}

resource "aws_eip_association" "terraform_eip_assoc" {
  instance_id   = module.terraform_ec2.ec2_instance_id
  allocation_id = module.terraform_eip.eip_id
}

module "terraform_ebs" {
  source = "../modules/ebs"
  AZ     = var.terraform_AZ
  size   = 10
  ebs_tag = {
    Name = "terraform_ebs"
  }
}

resource "aws_volume_attachment" "terraform_ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = module.terraform_ebs.aws_ebs_volume_id
  instance_id = module.terraform_ec2.ec2_instance_id
}

resource "null_resource" "output_metadatas" {
  depends_on = [
    module.terraform_eip
  ]
  provisioner "local-exec" {
    command = "echo PUBLIC_IP: ${module.terraform_eip.public_ip} - PUBLIC_DNS: ${module.terraform_eip.public_dns}  >> terraform_ec2.txt"
  }
}