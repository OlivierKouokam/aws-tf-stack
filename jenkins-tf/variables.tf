variable "static_key_name" {
  type    = string
  default = "devops-olivier"
}

variable "jenkins_AZ" {
  type    = string
  default = "us-east-1a"
}

variable "jenkins_region" {
  type    = string
  default = "us-east-1"
}

variable "jenkins_cidr_blocks" {
  type = list(string)
  default = [ "0.0.0.0/0" ]
}