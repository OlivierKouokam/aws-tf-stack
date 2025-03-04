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

# gitlab {
#   backend "s3" {
#     region     = "us-east-1"
#     # access_key = "YOUR-ACCESS-KEY"
#     # secret_key = "YOUR-SECRET-KEY"
#     shared_credentials_files = ["../.secrets/credentials"]
#     bucket = "backend-eazyastuces"
#     key = "eazy-astuce.tfstate"
#   }
# }

provider "aws" {
  region = "us-east-1"
  # access_key = "YOUR-ACCESS-KEY"
  # secret_key = "YOUR-SECRET-KEY"
  shared_credentials_files = ["../.secrets/credentials"]
  profile                  = "stack"
}

module "gitlab_vpc" {
  source         = "../modules/vpc"
  vpc_name       = "gitlab-vpc"
  vpc_cidr_block = "10.2.0.0/16"
}

module "public_subnet" {
  source            = "../modules/subnet"
  vpc_id            = module.gitlab_vpc.stack_vpc_id
  subnet_cidr_block = "10.2.1.0/24"
  subnet_name       = "gitlab_public_subnet"
  subnet_AZ         = var.gitlab_AZ
}

module "gitlab_igw" {
  source   = "../modules/igw"
  igw_name = "gitlab_igw"
  vpc_id   = module.gitlab_vpc.stack_vpc_id
}

module "gitlab_route_table" {
  source           = "../modules/route_table"
  vpc_id           = module.gitlab_vpc.stack_vpc_id
  route_table_name = "gitlab_route_table"
}

resource "aws_route" "internet_access" {
  route_table_id         = module.gitlab_route_table.route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.gitlab_igw.igw_id
}

resource "aws_route_table_association" "public_subnet_to_docker_igw" {
  subnet_id      = module.public_subnet.subnet_id
  route_table_id = module.gitlab_route_table.route_table_id
}

module "sg" {
  source  = "../modules/sg"
  sg_name = "gitalb-sg"
  vpc_id         = module.gitlab_vpc.stack_vpc_id
  vpc_cidr_block = ["0.0.0.0/0"]
}

module "keypair" {
  source           = "../modules/keypair"
  key_name         = "devops-gitlab"
  private_key_path = "../.secrets/${module.keypair.key_name}.pem"
}

module "gitlab-ec2" {
  depends_on    = [module.sg, module.keypair]
  source        = "../modules/ec2"
  subnet_id     = module.public_subnet.subnet_id
  instance_type = "t3.medium"
  aws_common_tag = {
    Name = "gitlab-ec2"
  }
  key_name = module.keypair.key_name
  # key_name        = var.static_key_name
  security_group_ids = [ module.sg.aws_sg_id ]
  # security_groups = [module.sg.aws_sg_name]
  private_key     = module.keypair.private_key
  # private_key     = ""
  user_data_path = "../scripts/userdata_gitlab.sh"
}

module "staging-ec2" {
  depends_on    = [module.sg, module.keypair]
  source        = "../modules/ec2"
  subnet_id     = module.public_subnet.subnet_id
  instance_type = "t3.medium"
  aws_common_tag = {
    Name = "staging-ec2"
  }
  key_name = module.keypair.key_name
  # key_name        = var.static_key_name
  security_group_ids = [ module.sg.aws_sg_id ]
  # security_groups = [module.sg.aws_sg_name]
  private_key     = module.keypair.private_key
  # private_key     = ""
  user_data_path = "../scripts/userdata_docker.sh"
}

module "production-ec2" {
  depends_on    = [module.sg, module.keypair]
  source        = "../modules/ec2"
  subnet_id     = module.public_subnet.subnet_id
  instance_type = "t3.medium"
  aws_common_tag = {
    Name = "production-ec2"
  }
  key_name = module.keypair.key_name
  # key_name        = var.static_key_name
  # security_groups = [module.sg.aws_sg_name]
  security_group_ids = [ module.sg.aws_sg_id ]
  private_key     = module.keypair.private_key
  # private_key     = ""
  user_data_path = "../scripts/userdata_docker.sh"
}

module "gitlab_eip" {
  source = "../modules/eip"
  eip_tags = {
    Name = "gitlab_eip"
  }
}

resource "aws_eip_association" "gitlab_eip_assoc" {
  instance_id = module.gitlab-ec2.ec2_instance_id
  allocation_id = module.gitlab_eip.eip_id
}

resource "null_resource" "output_metadatas" {
  depends_on = [resource.aws_eip_association.gitlab_eip_assoc]
  provisioner "local-exec" {
    command = "echo PUBLIC_IP: ${module.gitlab-ec2.public_ip} - PUBLIC_DNS: ${module.gitlab-ec2.public_dns}  > gitlab_ec2.txt"
  }
}