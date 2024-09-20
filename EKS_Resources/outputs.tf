output "eks_cluster_endpoint" {
  description = "The endpoint for your EKS cluster."
  value       = aws_eks_cluster.eks_cluster.endpoint
}

output "vpc_id" {
  description = "The ID of the VPC created for EKS."
  value       = aws_vpc.eks_vpc.id
}

output "eks_cluster_certificate_authority" {
  value = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}

output "eks_cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "region" {
  value = var.region
}

output "eks_cluster" {
  value = aws_eks_cluster.eks_cluster
}