output "eks_cluster_endpoint" {
  value = data.terraform_remote_state.eks.outputs.eks_cluster_endpoint
}

output "eks_cluster_certificate_authority" {
  value = data.terraform_remote_state.eks.outputs.eks_cluster_certificate_authority
}

output "eks_cluster_name" {
  value = data.terraform_remote_state.eks.outputs.eks_cluster_name
}

output "url" {
  value = aws_iam_openid_connect_provider.oidc_provider.url
}