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
}

provider "aws" {
  region = "us-east-1"
  # access_key = "YOUR-ACCESS-KEY"
  # secret_key = "YOUR-SECRET-KEY"
  shared_credentials_files = ["../../.secrets/credentials"]
  profile                  = "default"
}

variable "static_key_name" {
  type = string
  default = "devops-olivier"
}

module "docker-ec2" {
  # depends_on    = [module.sg, module.keypair]
  source        = "../modules/ec2"
  instance_type = "t2.medium"
  aws_common_tag = {
    Name = "docker-ec2"
  }
  key_name        = module.keypair.key_name
  # key_name        = var.static_key_name
  security_groups = [module.sg.aws_sg_name]
  private_key     = module.keypair.private_key
  # private_key     = ""
  user_data_path  = "./userdata_docker.sh"
}


module "keypair" {
  source   = "../modules/keypair"
  key_name = "devops-docker"
}


module "sg" {
  source  = "../modules/sg" 
  sg_name = "docker-sg"  
}

module "vpc" {
  source  = "../modules/vpc"
  vpc_name = "docker-vpc"
}



resource "null_resource" "output_metadatas" {
  depends_on = [module.docker-ec2]
  provisioner "local-exec" {
    command = "echo PUBLIC_IP: ${module.docker-ec2.public_ip} - PUBLIC_DNS: ${module.docker-ec2.public_dns}  > docker_ec2.txt"
  }
}