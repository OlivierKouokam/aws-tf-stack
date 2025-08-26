locals {
  private_key_path = "${path.module}/keys/${local.key_name}.pem"
  key_name         = var.project_name
  projet           = var.project_name

}
# network configuration
data "aws_availability_zones" "available" {}
module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "~> 5.0"
  name                 = "${var.project_name}-vpc"
  cidr                 = var.vpc_cidr
  azs                  = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets       = var.public_subnets
  private_subnets      = var.private_subnets
  enable_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}

module "sg" {
  source      = "./modules/sg"
  name        = "${var.project_name}-sg"
  description = "SG"
  vpc_id      = module.vpc.vpc_id
  /*
  ingress_rules = [
    { from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = var.ssh_cidr_blocks, description = "SSH" },
    { from_port = 6443, to_port = 6443, protocol = "tcp", cidr_blocks = [var.vpc_cidr], description = "K8s API" },
    { from_port = 8080, to_port = 8080, protocol = "tcp", cidr_blocks = [var.vpc_cidr], description = "k8s server" },
    { from_port = 30000, to_port = 32767, protocol = "tcp", cidr_blocks = [var.vpc_cidr], description = "NodePort" },
    { from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "HTTP" },
    { from_port = 10250, to_port = 10250, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "kubelet" },
    { from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "HTTPS" }
  ]
  */
  ingress_rules = [
    { from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = var.ssh_cidr_blocks, description = "SSH" },
    { from_port = 6443, to_port = 6443, protocol = "tcp", cidr_blocks = [var.vpc_cidr], description = "K8s API" },
    { from_port = 30000, to_port = 32767, protocol = "tcp", cidr_blocks = [var.vpc_cidr], description = "NodePort" },
    { from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "HTTP" },
    { from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "HTTPS" },
    # Composants Kubernetes
    { from_port = 10250, to_port = 10250, protocol = "tcp", cidr_blocks = [var.vpc_cidr], description = "kubelet" },
    { from_port = 2379, to_port = 2380, protocol = "tcp", cidr_blocks = [var.vpc_cidr], description = "etcd" },
    { from_port = 10251, to_port = 10251, protocol = "tcp", cidr_blocks = [var.vpc_cidr], description = "kube-scheduler" },
    { from_port = 10252, to_port = 10252, protocol = "tcp", cidr_blocks = [var.vpc_cidr], description = "kube-controller-manager" },
    # CNI (ajustez selon votre CNI)
    { from_port = 8472, to_port = 8472, protocol = "udp", cidr_blocks = [var.vpc_cidr], description = "Flannel VXLAN" },
    { from_port = 30000, to_port = 32767, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "NodePort" },
  ]
  egress_rules = [
    { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"], description = "All outbound" }
  ]
}

module "iam" {
  source   = "./modules/iam"
  iam_name = "${local.projet}_role"
}



# keypair configuration
module "keypair" {
  source   = "./modules/keypair"
  key_name = local.key_name
  key_path = local.private_key_path
}

module "k8s_master" {
  source               = "./modules/ec2"
  ami_id               = data.aws_ami.ubuntu_24_04.id
  instance_type        = var.instance_type
  instance_role        = "master"
  cluster_cidr         = var.cluster_cidr
  key_name             = local.key_name
  subnets              = module.vpc.public_subnets
  security_group_id    = module.sg.sg_id
  iam_instance_profile = module.iam.iam_role_name
  region               = var.region
  ssm_param_name       = var.ssm_param_name
  worker_number        = var.master_count
  volume_size          = var.volume_size
  volume_type          = var.volume_type
  user_data_template   = "${path.module}/scripts/master-init.sh"
  k8s_version          = var.k8s_version
}

module "k8s_worker" {
  source               = "./modules/ec2"
  ami_id               = data.aws_ami.ubuntu_24_04.id
  cluster_cidr         = var.cluster_cidr
  instance_type        = var.instance_type
  instance_role        = "worker"
  key_name             = local.key_name
  subnets              = module.vpc.public_subnets
  security_group_id    = module.sg.sg_id
  iam_instance_profile = module.iam.iam_role_name
  region               = var.region
  ssm_param_name       = var.ssm_param_name
  worker_number        = var.worker_count
  volume_size          = var.volume_size
  volume_type          = var.volume_type
  user_data_template   = "${path.module}/scripts/worker-init.sh"
  k8s_version          = var.k8s_version
}

# Provisioner pour initialiser les masters
resource "null_resource" "master_init" {
  count = length(module.k8s_master.public_ips)

  # Dépendance explicite pour s'assurer que les instances sont prêtes
  depends_on = [module.k8s_master]

  triggers = {
    instance_ip = module.k8s_master.public_ips[count.index]
  }

  provisioner "file" {
    source      = "scripts/master-init.sh"
    destination = "/tmp/master-init.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(local.private_key_path)
      host        = self.triggers.instance_ip
      timeout     = "5m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/master-init.sh",
      "REGION=${var.region} SSM_PARAM=${var.ssm_param_name} K8S_VERSION=${var.k8s_version} CLUSTER_CIDR=${var.cluster_cidr} bash /tmp/master-init.sh"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(local.private_key_path)
      host        = self.triggers.instance_ip
      timeout     = "10m"
    }
  }
}

# Provisioner pour initialiser les workers
resource "null_resource" "worker_init" {
  count = length(module.k8s_worker.public_ips)

  # Dépendance pour s'assurer que les workers sont initialisés après les masters
  depends_on = [module.k8s_worker, null_resource.master_init]

  triggers = {
    instance_ip = module.k8s_worker.public_ips[count.index]
    # Trigger sur le master pour redéployer les workers si le master change
    master_ips = join(",", module.k8s_master.public_ips)
  }

  provisioner "file" {
    source      = "scripts/worker-init.sh"
    destination = "/tmp/worker-init.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(local.private_key_path)
      host        = self.triggers.instance_ip
      timeout     = "5m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/worker-init.sh",
      "REGION=${var.region} SSM_PARAM=${var.ssm_param_name} K8S_VERSION=${var.k8s_version} CLUSTER_CIDR=${var.cluster_cidr} MASTER_IP=${module.k8s_master.public_ips[0]} bash /tmp/worker-init.sh"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(local.private_key_path)
      host        = self.triggers.instance_ip
      timeout     = "10m"
    }
  }
}
