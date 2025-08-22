variable "cluster_name" {
  description = "Nom du cluster EKS"
  type        = string
}

variable "cluster_version" {
  description = "Version de Kubernetes"
  type        = string
  default     = "1.28"
}

variable "region" {
  description = "Région AWS"
  type        = string
  # default     = "eu-west-3"  # Paris
  default     = "us-east-1"  # Virginie du Nord
}

variable "vpc_id" {
  description = "ID du VPC existant"
  type        = string
}

variable "subnet_ids" {
  description = "Liste des IDs des sous-réseaux"
  type        = list(string)
}

variable "node_group_name" {
  description = "Nom du node group"
  type        = string
  default     = "worker-nodes"
}

variable "instance_types" {
  description = "Types d'instances pour les nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "desired_size" {
  description = "Nombre désiré de nodes"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Nombre maximum de nodes"
  type        = number
  default     = 3
}

variable "min_size" {
  description = "Nombre minimum de nodes"
  type        = number
  default     = 1
}