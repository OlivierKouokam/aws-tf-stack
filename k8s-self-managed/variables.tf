variable "instance_type" {}
variable "region" {}
variable "ssm_param_name" {}

variable "cluster_cidr" {

}
variable "k8s_version" {

}
variable "public_subnets" {
  description = "Liste des CIDR des subnets publics"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "Liste des CIDR des subnets privés"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "ssh_cidr_blocks" {
  description = "IP autorisées pour SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR du VPC"
  type        = string
  default     = "10.0.0.0/16"
}
variable "project_name" {}
variable "environment" {}
variable "worker_count" {
}
variable "master_count" {
}
variable "volume_size" {
}
variable "volume_type" {

}