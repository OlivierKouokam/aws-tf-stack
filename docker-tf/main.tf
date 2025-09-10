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
  region                   = var.docker_region
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
  sg_vpc_id         = module.docker_vpc.stack_vpc_id
  sg_cidr_block = var.docker_cidr_blocks
  sg_ingress_rules = [
    { protocol = -1, cidr_blocks = var.docker_cidr_blocks, description = "allow all traffic" }
  ]
}

module "keypair" {
  source           = "../modules/keypair"
  key_name         = "devops-docker"
  private_key_path = "../.secrets/${module.keypair.key_name}.pem"
}

/*
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
*/

module "stack_ec2" {
  for_each = {
    docker     = { name = "docker-ec2", user_data = "../scripts/userdata_docker.sh" }
    staging    = { name = "staging-ec2", user_data = "../scripts/userdata_worker.sh" }
    production = { name = "production-ec2", user_data = "../scripts/userdata_worker.sh" }
  }

  source             = "../modules/ec2"
  subnet_id          = module.public_subnet.subnet_id
  instance_type      = "t3.medium"
  ec2_root_volume_size = 50
  aws_common_tag     = { Name = "${each.key}-ec2" }
  key_name           = module.keypair.key_name
  security_group_ids = [module.sg.aws_sg_id]
  private_key        = module.keypair.private_key
  user_data_path     = each.value.user_data
}

/*
module "docker_eip" {
  depends_on = [ module.docker_ec2 ]
  source = "../modules/eip"
  eip_tags = {
    Name = "docker_eip"
  }
}

module "staging_eip" {
  depends_on = [ module.staging_ec2]
  source = "../modules/eip"
  eip_tags = {
    Name = "staging_eip"
  }
}

module "production_eip" {
  depends_on = [ module.staging_ec2]
  source = "../modules/eip"
  eip_tags = {
    Name = "production_eip"
  }
}
*/

module "stack_eip" {
  for_each = toset(["docker", "staging", "production"])

  source = "../modules/eip"

  eip_tags = {
    Name = "${each.key}_eip"
  }

  depends_on = [
    module.stack_ec2
  ]
}

/*
module "docker_ebs" {
  source = "../modules/ebs"
  AZ     = var.docker_AZ
  size   = 20
  ebs_tag = {
    Name = "docker_ebs"
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

module "production_ebs" {
  source = "../modules/ebs"
  AZ     = var.docker_AZ
  size   = 20
  ebs_tag = {
    Name = "production_ebs"
  }
}
*/

module "stack_ebs" {
  for_each = {
    docker     = { az = var.docker_AZ, size = 20 }
    staging    = { az = var.docker_AZ, size = 20 }
    production = { az = var.docker_AZ, size = 20 }
  }

  source = "../modules/ebs"

  AZ   = each.value.az
  size = each.value.size

  ebs_tag = {
    Name = "${each.key}_ebs"
  }
}

/*
resource "aws_eip_association" "docker_eip_assoc" {
  instance_id   = module.docker_ec2.ec2_instance_id
  allocation_id = module.docker_eip.eip_id
}

resource "aws_eip_association" "staging_eip_assoc" {
  instance_id   = module.staging_ec2.ec2_instance_id
  allocation_id = module.staging_eip.eip_id
}

resource "aws_eip_association" "production_eip_assoc" {
  instance_id   = module.production_ec2.ec2_instance_id
  allocation_id = module.production_eip.eip_id
}

resource "aws_eip_association" "eip_assoc" {
  for_each = {
    docker     = {
      instance_id   = module.docker_ec2.ec2_instance_id
      allocation_id = module.docker_eip.eip_id
    }
    staging    = {
      instance_id   = module.staging_ec2.ec2_instance_id
      allocation_id = module.staging_eip.eip_id
    }
    production = {
      instance_id   = module.production_ec2.ec2_instance_id
      allocation_id = module.production_eip.eip_id
    }
  }

  instance_id   = each.value.instance_id
  allocation_id = each.value.allocation_id
}
*/

resource "aws_eip_association" "eip_assoc" {
  for_each = toset(["docker", "staging", "production"])

  instance_id   = module.stack_ec2[each.key].ec2_instance_id
  allocation_id = module.stack_eip[each.key].eip_id
}

/*
resource "aws_volume_attachment" "docker_ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = module.docker_ebs.aws_ebs_volume_id
  instance_id = module.docker_ec2.ec2_instance_id
}

resource "aws_volume_attachment" "staging_ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = module.staging_ebs.aws_ebs_volume_id
  instance_id = module.staging_ec2.ec2_instance_id
}

resource "aws_volume_attachment" "production_ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = module.production_ebs.aws_ebs_volume_id
  instance_id = module.production_ec2.ec2_instance_id
}

resource "aws_volume_attachment" "ebs_att" {
  for_each = {
    docker     = {
      volume_id   = module.docker_ebs.aws_ebs_volume_id
      instance_id = module.docker_ec2.ec2_instance_id
    }
    staging    = {
      volume_id   = module.staging_ebs.aws_ebs_volume_id
      instance_id = module.staging_ec2.ec2_instance_id
    }
    production = {
      volume_id   = module.production_ebs.aws_ebs_volume_id
      instance_id = module.production_ec2.ec2_instance_id
    }
  }

  device_name = "/dev/sdh"
  volume_id   = each.value.volume_id
  instance_id = each.value.instance_id
  force_detach = true # facultatif, selon besoin
}
*/

resource "aws_volume_attachment" "ebs_att" {
  for_each = toset(["docker", "staging", "production"])

  device_name  = "/dev/sdh"
  volume_id    = module.stack_ebs[each.key].aws_ebs_volume_id
  instance_id  = module.stack_ec2[each.key].ec2_instance_id
  force_detach = true
}

/*
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
*/

resource "null_resource" "output_metadatas" {
  depends_on = [module.stack_ec2, module.stack_eip]

  provisioner "local-exec" {
    command = "echo Docker PUBLIC_IP: ${module.stack_eip["docker"].public_ip} - Docker PUBLIC_DNS: ${module.stack_eip["docker"].public_dns}  >> docker_ec2.txt"
  }

  provisioner "local-exec" {
    command = "echo Staging PUBLIC_IP: ${module.stack_eip["staging"].public_ip} - Staging PUBLIC_DNS: ${module.stack_eip["staging"].public_dns}  >> docker_ec2.txt"
  }

  provisioner "local-exec" {
    command = "echo Production PUBLIC_IP: ${module.stack_eip["production"].public_ip} - Production PUBLIC_DNS: ${module.stack_eip["production"].public_dns}  >> docker_ec2.txt"
  }
}
