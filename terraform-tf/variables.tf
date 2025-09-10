variable "terraform_AZ" {
  type    = string
  default = "us-east-1a"
}

variable "terraform_region" {
  type    = string
  default = "us-east-1"
}

variable "tf_cidr_blocks" {
  type = list(string)
  default = [ "0.0.0.0/0" ]
}