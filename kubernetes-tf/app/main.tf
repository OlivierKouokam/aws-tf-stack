# kubernetes {
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
  shared_credentials_files = ["../../.secrets/credentials"]
  profile                  = "default"
}

variable "static_key_name" {
  type = string
  default = "devops-olivier"
}

module "kubernetes-ec2" {
  # depends_on    = [module.sg, module.keypair]
  source        = "../modules/ec2"
  instance_type = "t2.medium"
  aws_common_tag = {
    Name = "kubernetes-ec2"
  }
  key_name        = module.keypair.key_name
  # key_name        = var.static_key_name
  security_groups = [module.sg.aws_sg_name]
  private_key     = module.keypair.private_key
  # private_key     = ""
  # user_data_path  = "./userdata_kubernetes.sh"
  user_data_path  = "./userdata_minikube.sh"
}

 
module "worker1-ec2" {
  depends_on    = [module.sg, module.keypair]
  source        = "../modules/ec2"
  instance_type = "t2.medium"
  aws_common_tag = {
    Name = "worker1-ec2"
  }
  key_name        = module.keypair.key_name
  # key_name        = var.static_key_name
  security_groups = [module.sg.aws_sg_name]
  private_key     = module.keypair.private_key
  # private_key     = ""
  user_data_path  = "./userdata_worker.sh"
}
/*
module "worker2-ec2" {
  depends_on    = [module.sg, module.keypair]
  source        = "../modules/ec2"
  instance_type = "t2.medium"
  aws_common_tag = {
    Name = "worker2-ec2"
  }
  key_name        = module.keypair.key_name
  # key_name        = var.static_key_name
  security_groups = [module.sg.aws_sg_name]
  private_key     = module.keypair.private_key
  # private_key     = ""
  user_data_path  = "./userdata_worker.sh"
}
 */
module "keypair" {
  source   = "../modules/keypair"
  key_name = "devops-kubernetes"
}


module "sg" {
  source  = "../modules/sg" 
  sg_name = "kubernetes-sg"  
}

module "vpc" {
  source  = "../modules/vpc"
  vpc_name = "kubernetes-vpc"
}



resource "null_resource" "output_metadatas" {
  depends_on = [module.kubernetes-ec2]
  provisioner "local-exec" {
    command = "echo PUBLIC_IP: ${module.kubernetes-ec2.public_ip} - PUBLIC_DNS: ${module.kubernetes-ec2.public_dns}  > kubernetes_ec2.txt"
  }
}