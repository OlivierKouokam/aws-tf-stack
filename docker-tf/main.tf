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
  region = var.docker_region
  # access_key = "YOUR-ACCESS-KEY"
  # secret_key = "YOUR-SECRET-KEY"
  shared_credentials_files = ["../.secrets/credentials"]
  profile                  = "stack"
}

module "docker_vpc" {
  source         = "../modules/vpc"
  vpc_name       = "docker-vpc"
  vpc_cidr_block = "10.1.0.0/16"
}

module "public_subnet" {
  source            = "../modules/subnet"
  vpc_id            = module.docker_vpc.stack_vpc_id
  subnet_cidr_block = "10.1.1.0/24"
  subnet_name       = "docker_public_subnet"
  subnet_AZ         = var.docker_AZ
}

module "docker_igw" {
  source   = "../modules/igw"
  igw_name = "docker_igw"
  vpc_id   = module.docker_vpc.stack_vpc_id
}

module "docker_route_table" {
  source           = "../modules/route_table"
  vpc_id           = module.docker_vpc.stack_vpc_id
  route_table_name = "docker_route_table"
}

resource "aws_route" "internet_access" {
  route_table_id         = module.docker_route_table.route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.docker_igw.igw_id
}

resource "aws_route_table_association" "public_subnet_to_docker_igw" {
  subnet_id      = module.public_subnet.subnet_id
  route_table_id = module.docker_route_table.route_table_id
}

module "sg" {
  source  = "../modules/sg"
  sg_name = "docker-sg"
  vpc_id         = module.docker_vpc.stack_vpc_id
  vpc_cidr_block = ["0.0.0.0/0"]
}

module "keypair" {
  source           = "../modules/keypair"
  key_name         = "devops-docker"
  private_key_path = "../.secrets/${module.keypair.key_name}.pem"
}

module "docker-ec2" {
  depends_on    = [module.sg, module.keypair]
  source        = "../modules/ec2"
  subnet_id     = module.public_subnet.subnet_id
  instance_type = "t3.medium"
  aws_common_tag = {
    Name = "docker-ec2"
  }
  key_name        = module.keypair.key_name
  security_group_ids = [ module.sg.aws_sg_id ]
  # security_groups = [module.sg.aws_sg_name]
  private_key     = module.keypair.private_key
  user_data_path  = "../scripts/userdata_docker.sh"
}

module "docker_eip" {
  source = "../modules/eip"
  eip_tags = {
    Name = "docker_eip"
  }
}

resource "aws_eip_association" "docker_eip_assoc" {
  instance_id = module.docker-ec2.ec2_instance_id
  allocation_id = module.docker_eip.eip_id
}

resource "null_resource" "outputs_metadatas" {
  depends_on = [resource.aws_eip_association.docker_eip_assoc, ]
  provisioner "local-exec" {
    command = "echo PUBLIC_IP: ${module.docker-ec2.public_ip} - PUBLIC_DNS: ${module.docker-ec2.public_dns}  > docker_ec2.txt"
  }
}