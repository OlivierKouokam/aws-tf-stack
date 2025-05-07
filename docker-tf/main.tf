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
  source         = "../modules/sg"
  sg_name        = "docker-sg"
  vpc_id         = module.docker_vpc.stack_vpc_id
  vpc_cidr_block = ["0.0.0.0/0"]
}

module "keypair" {
  source           = "../modules/keypair"
  key_name         = "devops-docker"
  private_key_path = "../.secrets/${module.keypair.key_name}.pem"
}

module "docker_ec2" {
  depends_on    = [module.sg, module.keypair]
  source        = "../modules/ec2"
  subnet_id     = module.public_subnet.subnet_id
  instance_type = "t3.medium"
  aws_common_tag = {
    Name = "docker-ec2"
  }
  key_name           = module.keypair.key_name
  security_group_ids = [module.sg.aws_sg_id]
  # security_groups = [module.sg.aws_sg_name]
  private_key    = module.keypair.private_key
  user_data_path = "../scripts/userdata_docker.sh"
}

module "staging_ec2" {
  depends_on    = [module.sg, module.keypair]
  source        = "../modules/ec2"
  subnet_id     = module.public_subnet.subnet_id
  instance_type = "t3.medium"
  aws_common_tag = {
    Name = "staging-ec2"
  }
  key_name           = module.keypair.key_name
  security_group_ids = [module.sg.aws_sg_id]
  # security_groups = [module.sg.aws_sg_name]
  private_key    = module.keypair.private_key
  user_data_path = "../scripts/userdata_worker.sh"
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

module "docker_eip" {
  depends_on = [ module.docker_ec2 ]
  source = "../modules/eip"
  eip_tags = {
    Name = "docker_eip"
  }
}

module "docker_ebs" {
  source = "../modules/ebs"
  AZ     = var.docker_AZ
  size   = 20
  ebs_tag = {
    Name = "docker_ebs"
  }
}

resource "aws_eip_association" "docker_eip_assoc" {
  instance_id   = module.docker_ec2.ec2_instance_id
  allocation_id = module.docker_eip.eip_id
}

resource "aws_volume_attachment" "docker_ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = module.docker_ebs.aws_ebs_volume_id
  instance_id = module.docker_ec2.ec2_instance_id
}

module "staging_eip" {
  depends_on = [ module.staging_ec2]
  source = "../modules/eip"
  eip_tags = {
    Name = "staging_eip"
  }
}

module "staging_ebs" {
  source = "../modules/ebs"
  AZ     = var.docker_AZ
  size   = 20
  ebs_tag = {
    Name = "staging_ebs"
  }
}

resource "aws_eip_association" "staging_eip_assoc" {
  instance_id   = module.staging_ec2.ec2_instance_id
  allocation_id = module.staging_eip.eip_id
}

resource "aws_volume_attachment" "staging_ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = module.staging_ebs.aws_ebs_volume_id
  instance_id = module.staging_ec2.ec2_instance_id
}

module "production_eip" {
  depends_on = [ module.staging_ec2]
  source = "../modules/eip"
  eip_tags = {
    Name = "production_eip"
  }
}

module "production_ebs" {
  source = "../modules/ebs"
  AZ     = var.docker_AZ
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
  depends_on = [module.docker_ec2, module.staging_ec2, module.production_ec2]
  
  provisioner "local-exec" {
  #   command = <<EOT
  #     echo docker-ec2-IP-DNS
  #     echo PUBLIC_IP: ${module.docker_ec2.public_ip} - PUBLIC_DNS: ${module.docker_ec2.public_dns}  > docker_ec2.txt
  #   EOT
  command = "echo Docker PUBLIC_IP: ${module.docker_eip.public_ip} - Docker PUBLIC_DNS: ${module.docker_eip.public_dns}  >> docker_ec2.txt"
  }

  provisioner "local-exec" {
    command = "echo Staging PUBLIC_IP: ${module.staging_eip.public_ip} - Staging PUBLIC_DNS: ${module.staging_eip.public_dns}  >> docker_ec2.txt"
  }

  provisioner "local-exec" {
    command = "echo Production PUBLIC_IP: ${module.production_eip.public_ip} - Production PUBLIC_DNS: ${module.production_eip.public_dns}  >> docker_ec2.txt"
  }
}