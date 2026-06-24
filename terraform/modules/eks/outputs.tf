output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.pitwall.name
}

output "cluster_endpoint" {
  description = "Endpoint URL for the EKS cluster API"
  value       = aws_eks_cluster.pitwall.endpoint
}

output "cluster_version" {
  description = "Kubernetes version running on the cluster"
  value       = aws_eks_cluster.pitwall.version
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.eks_cluster.id
}

output "node_group_name" {
  description = "Name of the EKS node group"
  value       = aws_eks_node_group.pitwall.node_group_name
}