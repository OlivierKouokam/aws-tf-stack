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
  region = var.ansible_region
  # access_key = "YOUR-ACCESS-KEY"
  # secret_key = "YOUR-SECRET-KEY"
  shared_credentials_files = ["../.secrets/credentials"]
  profile                  = "stack"
}

module "vpc" {
  source         = "../modules/vpc"
  vpc_name       = "ansible-vpc"
  vpc_cidr_block = "10.2.0.0/16"
}

module "public_subnet" {
  source            = "../modules/subnet"
  vpc_id            = module.vpc.stack_vpc_id
  subnet_cidr_block = "10.2.1.0/24"
  subnet_name       = "ansible_public_subnet"
  subnet_AZ         = var.ansible_AZ
}

module "ansible_igw" {
  source   = "../modules/igw"
  igw_name = "ansible_igw"
  vpc_id   = module.vpc.stack_vpc_id
}

module "ansible_route_table" {
  source           = "../modules/route_table"
  vpc_id           = module.vpc.stack_vpc_id
  route_table_name = "ansible_route_table"
}

resource "aws_route" "internet_access" {
  route_table_id         = module.ansible_route_table.route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.ansible_igw.igw_id
}

resource "aws_route_table_association" "public_subnet_to_ansible_igw" {
  subnet_id      = module.public_subnet.subnet_id
  route_table_id = module.ansible_route_table.route_table_id
}

module "sg" {
  source         = "../modules/sg"
  sg_name        = "ansible-sg"
  vpc_id         = module.vpc.stack_vpc_id
  vpc_cidr_block = ["0.0.0.0/0"]
}

module "keypair" {
  source           = "../modules/keypair"
  key_name         = "devops-ansible"
  private_key_path = "../.secrets/${module.keypair.key_name}.pem"
}

module "ansible-ec2" {
  depends_on = [
    module.sg, module.keypair,
    resource.aws_route_table_association.public_subnet_to_ansible_igw
  ]
  source        = "../modules/ec2"
  subnet_id     = module.public_subnet.subnet_id
  instance_type = "t3.medium"
  aws_common_tag = {
    Name = "ansible-ec2"
  }
  key_name = module.keypair.key_name
  # key_name        = var.static_key_name
  security_group_ids = [module.sg.aws_sg_id]
  # security_groups = [module.sg.aws_sg_name]
  private_key = module.keypair.private_key
  # private_key     = ""
  user_data_path = "../scripts/userdata_ansible.sh"
}

module "staging-ec2" {
  depends_on    = [module.sg, module.keypair]
  source        = "../modules/ec2"
  subnet_id     = module.public_subnet.subnet_id
  instance_type = "t3.medium"
  aws_common_tag = {
    Name = "staging-ansible"
  }
  key_name = module.keypair.key_name
  # key_name        = var.static_key_name
  security_group_ids = [module.sg.aws_sg_id]
  # security_groups = [module.sg.aws_sg_name]
  private_key = module.keypair.private_key
  # private_key     = ""
  user_data_path = "../scripts/userdata_docker.sh"
}

module "production-ec2" {
  depends_on    = [module.sg, module.keypair]
  source        = "../modules/ec2"
  subnet_id     = module.public_subnet.subnet_id
  instance_type = "t3.medium"
  aws_common_tag = {
    Name = "production-ansible"
  }
  key_name = module.keypair.key_name
  # key_name        = var.static_key_name
  security_group_ids = [module.sg.aws_sg_id]
  # security_groups = [module.sg.aws_sg_name]
  private_key = module.keypair.private_key
  # private_key     = ""
  user_data_path = "../scripts/userdata_docker.sh"
}

module "ansible_eip" {
  depends_on = [resource.aws_route_table_association.public_subnet_to_ansible_igw]
  source     = "../modules/eip"
  eip_tags = {
    Name = "ansible_eip"
  }
}

module "prod_eip" {
  depends_on = [resource.aws_route_table_association.public_subnet_to_ansible_igw]
  source     = "../modules/eip"
  eip_tags = {
    Name = "prod_eip"
  }
}

module "stag_eip" {
  depends_on = [resource.aws_route_table_association.public_subnet_to_ansible_igw]
  source     = "../modules/eip"
  eip_tags = {
    Name = "stag_eip"
  }
}

resource "aws_eip_association" "ansible_eip_assoc" {
  instance_id   = module.ansible-ec2.ec2_instance_id
  allocation_id = module.ansible_eip.eip_id
}

resource "aws_eip_association" "prod_eip_assoc" {
  instance_id   = module.production-ec2.ec2_instance_id
  allocation_id = module.prod_eip.eip_id
}

resource "aws_eip_association" "stag_eip_assoc" {
  instance_id   = module.staging-ec2.ec2_instance_id
  allocation_id = module.stag_eip.eip_id
}

resource "null_resource" "output_metadatas" {
  depends_on = [
    resource.aws_eip_association.ansible_eip_assoc,
    resource.aws_eip_association.prod_eip_assoc,
    resource.aws_eip_association.stag_eip_assoc
    # module.jenkins_eip, module.prod_eip, module.stag_eip
  ]
  provisioner "local-exec" {
    command = "echo PUBLIC_IP: ${module.ansible-ec2.public_ip} - PUBLIC_DNS: ${module.ansible-ec2.public_dns}  > ansible_ec2.txt;\n echo PUBLIC_IP: ${module.staging-ec2.public_ip} - PUBLIC_DNS: ${module.staging-ec2.public_dns}  > staging_ec2.txt;\n echo PUBLIC_IP: ${module.production-ec2.public_ip} - PUBLIC_DNS: ${module.production-ec2.public_dns}  > production_ec2.txt;\n"
  }
}