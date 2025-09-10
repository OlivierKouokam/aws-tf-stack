variable "static_key_name" {
  type    = string
  default = "devops-olivier"
}

variable "gitlab_AZ" {
  type    = string
  default = "us-east-1c"
}

variable "gitlab_region" {
  type    = string
  default = "us-east-1"
}

variable "gitlab_cidr_blocks" {
  type = list(string)
  default = [ "0.0.0.0/0" ]
}