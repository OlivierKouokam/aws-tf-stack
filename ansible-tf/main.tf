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
  region = "us-east-1"
  # access_key = "YOUR-ACCESS-KEY"
  # secret_key = "YOUR-SECRET-KEY"
  shared_credentials_files = ["../.secrets/credentials"]
  profile                  = "default"
}

variable "static_key_name" {
  type = string
  default = "devops-olivier"
}

module "ansible-ec2" {
  depends_on    = [module.sg, module.keypair]
  source        = "../modules/ec2"
  instance_type = "t2.medium"
  aws_common_tag = {
    Name = "ansible-ec2"
  }
  key_name        = module.keypair.key_name
  # key_name        = var.static_key_name
  security_groups = [module.sg.aws_sg_name]
  private_key     = module.keypair.private_key
  # private_key     = ""
  user_data_path  = "../scripts/userdata_ansible.sh"
}

module "staging-ec2" {
  depends_on    = [module.sg, module.keypair]
  source        = "../modules/ec2"
  instance_type = "t2.medium"
  aws_common_tag = {
    Name = "staging-ansible"
  }
  key_name        = module.keypair.key_name
  # key_name        = var.static_key_name
  security_groups = [module.sg.aws_sg_name]
  private_key     = module.keypair.private_key
  # private_key     = ""
  user_data_path  = "../scripts/userdata_docker.sh"
}

module "production-ec2" {
  depends_on    = [module.sg, module.keypair]
  source        = "../modules/ec2"
  instance_type = "t2.medium"
  aws_common_tag = {
    Name = "production-ansible"
  }
  key_name        = module.keypair.key_name
  # key_name        = var.static_key_name
  security_groups = [module.sg.aws_sg_name]
  private_key     = module.keypair.private_key
  # private_key     = ""
  user_data_path  = "../scripts/userdata_docker.sh"
}


module "keypair" {
  source   = "../modules/keypair"
  key_name = "devops-ansible"
  private_key_path = "../.secrets/${key_name}.pem"
}


module "sg" {
  source  = "../modules/sg" 
  sg_name = "ansible-sg"  
}

module "vpc" {
  source  = "../modules/vpc"
  vpc_name = "ansible-vpc"
}

resource "null_resource" "output_metadatas" {
  depends_on = [module.ansible-ec2, module.production-ec2, module.staging-ec2]
  provisioner "local-exec" {
    command = "echo PUBLIC_IP: ${module.ansible-ec2.public_ip} - PUBLIC_DNS: ${module.ansible-ec2.public_dns}  > ansible_ec2.txt;\n echo PUBLIC_IP: ${module.staging-ec2.public_ip} - PUBLIC_DNS: ${module.staging-ec2.public_dns}  > staging_ec2.txt;\n echo PUBLIC_IP: ${module.production-ec2.public_ip} - PUBLIC_DNS: ${module.production-ec2.public_dns}  > production_ec2.txt;\n"
  }
}