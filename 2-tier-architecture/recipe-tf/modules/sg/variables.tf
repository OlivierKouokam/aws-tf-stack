variable "sg_name" {
  type        = string
  description = "security group"
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = list(string)
}