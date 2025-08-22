provider "aws" {
  region = var.aws_region
  default_tags { tags = { Project = "k8s-cluster", Environment = var.environment, ManagedBy = "terraform" } }
}