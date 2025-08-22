variable "eip_association_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "nat_gw_tags" {
  type        = map(any)
  description = "NAT Gateway Tags"
  default = {
    Name = "my_nat_gw"
  }
}

variable "igw_association" {
  type = any
}