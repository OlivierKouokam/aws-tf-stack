variable "AZ" {
  type = string
  default = "us-east-1b"
}

variable "size" {
  type = number
  default = 15
}

variable "ebs_tag" {
  type        = map(any)
  description = "Tags for infrastructure resources."
  default = {
    Name = "ebs-volume"
  }
}