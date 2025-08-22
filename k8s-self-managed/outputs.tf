# # Outputs pour récupérer les adresses IP publiques
# output "k8s_master_public_ips" {
#   description = "Public IP addresses of Kubernetes master nodes"
#   value       = module.k8s_master.public_ips
# }

# output "k8s_worker_public_ips" {
#   description = "Public IP addresses of Kubernetes worker nodes"
#   value       = module.k8s_worker.public_ips
# }

# output "k8s_master_instance_ids" {
#   description = "Instance IDs of master nodes"
#   value       = module.k8s_master.instance_ids
# }

# output "k8s_worker_instance_ids" {
#   description = "Instance IDs of worker nodes"
#   value       = module.k8s_worker.instance_ids
# }

# Output formaté pour faciliter l'utilisation
# output "k8s_cluster_info" {
#   description = "Complete Kubernetes cluster information"
#   value = {
#     master_nodes = {
#       count       = length(module.k8s_master.public_ips)
#       public_ips  = module.k8s_master.public_ips
#       instance_ids = module.k8s_master.instance_ids
#     }
#     worker_nodes = {
#       count       = length(module.k8s_worker.public_ips)
#       public_ips  = module.k8s_worker.public_ips
#       instance_ids = module.k8s_worker.instance_ids
#     }
#     ssh_commands = {
#       master_ssh = [
#         for ip in module.k8s_master.public_ips :
#         "ssh -i ${var.private_key_path} ubuntu@${ip}"
#       ]
#       worker_ssh = [
#         for ip in module.k8s_worker.public_ips :
#         "ssh -i ${var.private_key_path} ubuntu@${ip}"
#       ]
#     }
#   }
# }