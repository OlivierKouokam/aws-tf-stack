variable "ami_id" {
  type = string
}
variable "instance_type" {}
variable "key_name" {}
variable "subnets" {}
variable "security_group_id" {}
variable "iam_instance_profile" {}
variable "instance_role" {}
variable "region" {}
variable "ssm_param_name" {}
variable "worker_number" {}
variable "volume_size" {}
variable "volume_type" {}
variable "user_data_template" {}
variable "k8s_version" {

}
variable "master_ip" {
  type    = string
  default = null
}

variable "cluster_cidr" {

}
