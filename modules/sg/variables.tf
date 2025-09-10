variable "sg_name" {
  type        = string
  description = "security group"
}

variable "sg_vpc_id" {
  type = string
}

variable "sg_cidr_block" {
  type = list(string)
}

variable "sg_ingress_rules" {
  description = "inbound traffic rules"
  type = list(object({
    from_port = number
    to_port = number
    protocol = string
    cidr_blocks = list(string)
    description = string
  }))

  default = [ ]
}

variable "sg_tags" {
  description = "some sg tags"
  type = map(string)
  default = {}
}

variable "sg_description" {
  type = string
  description = "description of the sg"
  default = "security group module"
}