provider "aws" {
  region = var.aws_region
  default_tags { tags = { Project = "k8s-cluster", Environment = var.environment, ManagedBy = "terraform" } }
  shared_credentials_files = ["../.secrets/credentials"]
  profile                  = "stack"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.79.0"
    }
  }

  required_version = "1.9.4"
}