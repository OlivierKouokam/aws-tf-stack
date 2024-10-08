module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "my-kubernetes-cluster"
  cluster_version = "1.31.1"
  subnets         = ["subnet-abc123", "subnet-def456"] # Replace with your subnets
  vpc_id          = "vpc-12345678"                    # Replace with your VPC ID

  node_groups = {
    my-nodes = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1

      instance_type = "t3.medium"
    }
  }

  enable_irsa = true
}
