resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = var.cluster_name  # Replace with your EKS cluster name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "region"
    value = var.region  # Replace with the AWS region
  }

  set {
    name  = "vpcId"
    value = aws_vpc.eks_vpc.id  # Replace with the VPC ID of your EKS cluster
  }

  depends_on = [
    aws_iam_role_policy_attachment.alb_controller_policy_attachment,
    aws_eks_cluster.eks_cluster
  ]
}