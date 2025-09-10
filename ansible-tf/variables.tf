variable "static_key_name" {
  type    = string
  default = "devops-olivier"
}

variable "ansible_AZ" {
  type    = string
  default = "us-east-1a"
}

variable "ansible_region" {
  type    = string
  default = "us-east-1"
}

variable "ansible_cidr_blocks" {
  type = list(string)
  default = [ "0.0.0.0/0" ]
}