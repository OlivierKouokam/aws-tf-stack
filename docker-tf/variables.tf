variable "static_key_name" {
  type    = string
  default = "devops-olivier"
}

variable "docker_AZ" {
  type    = string
  default = "us-east-1a"
}

variable "docker_region" {
  type    = string
  default = "us-east-1"
}

variable "docker_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}