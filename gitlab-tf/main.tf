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

variable "static_key_name" {
  type    = string
  default = "devops-olivier"
}

module "gitlab-ec2" {
  depends_on    = [module.sg, module.keypair]
  source        = "../modules/ec2"
  instance_type = "t2.medium"
  aws_common_tag = {
    Name = "gitlab-ec2"
  }
  key_name = module.keypair.key_name
  # key_name        = var.static_key_name
  security_groups = [module.sg.aws_sg_name]
  private_key     = module.keypair.private_key
  # private_key     = ""
  user_data_path = "../scripts/userdata_gitlab.sh"
}

module "staging-ec2" {
  depends_on    = [module.sg, module.keypair]
  source        = "../modules/ec2"
  instance_type = "t2.medium"
  aws_common_tag = {
    Name = "staging-ec2"
  }
  key_name = module.keypair.key_name
  # key_name        = var.static_key_name
  security_groups = [module.sg.aws_sg_name]
  private_key     = module.keypair.private_key
  # private_key     = ""
  user_data_path = "../scripts/userdata_docker.sh"
}

module "production-ec2" {
  depends_on    = [module.sg, module.keypair]
  source        = "../modules/ec2"
  instance_type = "t2.medium"
  aws_common_tag = {
    Name = "production-ec2"
  }
  key_name = module.keypair.key_name
  # key_name        = var.static_key_name
  security_groups = [module.sg.aws_sg_name]
  private_key     = module.keypair.private_key
  # private_key     = ""
  user_data_path = "../scripts/userdata_docker.sh"
}

module "keypair" {
  source   = "../modules/keypair"
  key_name = "devops-gitlab"
  private_key_path = "../.secrets/${module.keypair.key_name}.pem"
}


module "sg" {
  source  = "../modules/sg"
  sg_name = "gitlab-sg"
}

module "vpc" {
  source   = "../modules/vpc"
  vpc_name = "gitlab-vpc"
}



resource "null_resource" "output_metadatas" {
  depends_on = [module.gitlab-ec2]
  provisioner "local-exec" {
    command = "echo PUBLIC_IP: ${module.gitlab-ec2.public_ip} - PUBLIC_DNS: ${module.gitlab-ec2.public_dns}  > gitlab_ec2.txt"
  }
}