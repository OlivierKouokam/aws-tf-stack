project_name = "k8s-cluster"
environment  = "dev"
region       = "us-east-1"

vpc_cidr        = "10.0.0.0/16"
public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
ssh_cidr_blocks = ["0.0.0.0/0"]


k8s_version   = "v1.30"
master_count  = 1
worker_count  = 1
instance_type = "t3.medium"
volume_size   = 50
volume_type   = "gp3"

ssm_param_name = "/k8s/token"
cluster_cidr   = "10.244.0.0/16" 