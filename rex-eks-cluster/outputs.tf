output "cluster_endpoint" {
  description = "Endpoint du cluster EKS"
  value       = aws_eks_cluster.cluster.endpoint
}

output "cluster_name" {
  description = "Nom du cluster EKS"
  value       = aws_eks_cluster.cluster.name
}

output "cluster_certificate_authority_data" {
  description = "Données du certificat d'autorité"
  value       = aws_eks_cluster.cluster.certificate_authority[0].data
}

output "node_group_arn" {
  description = "ARN du node group"
  value       = aws_eks_node_group.nodes.arn
}