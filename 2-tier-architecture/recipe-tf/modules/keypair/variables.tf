variable "key_name" {
  type        = string
  description = "Set key name of the generator key pair"
  default     = "devops-terraform"
}

variable "private_key_path" {
  type        = string
  description = "Set private key path to save"
  default     = ".ssh"
}