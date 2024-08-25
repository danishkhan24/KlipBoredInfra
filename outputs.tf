output "eks_cluster_endpoint" {
  description = "The endpoint for your EKS cluster."
  value       = aws_eks_cluster.eks_cluster.endpoint
}

output "vpc_id" {
  description = "The ID of the VPC created for EKS."
  value       = aws_vpc.eks_vpc.id
}
