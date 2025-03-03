variable "key_name" {
  type        = string
  description = "key_name from keypair_module"
  default     = "k-name"
}

variable "instance_type" {
  type        = string
  description = "set aws instance type"
  default     = "t2.nano"
}

variable "aws_common_tag" {
  type        = map(any)
  description = "Tags for infrastructure resources."
  default = {
    Name = "ec2-dynamic-keypair"
  }
}

variable "security_groups" {
  type    = set(string)
  default = null
}

variable "security_group_ids" {
  type = set(string)
}

variable "private_key" {
}

variable "user_data_path" {
  type        = string
  description = "path of user data file"
}

variable "subnet_id" {
  type = string
}