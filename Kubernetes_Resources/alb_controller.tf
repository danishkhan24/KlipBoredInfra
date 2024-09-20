resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = data.terraform_remote_state.eks.outputs.eks_cluster_name  # Replace with your EKS cluster name
  }

  set {
    name  = "serviceAccount.create"
    value = false
  }

  # Use the existing service account name
  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.aws_load_balancer_controller_sa.metadata[0].name
  }

  set {
    name  = "region"
    value = data.terraform_remote_state.eks.outputs.region  # Replace with the AWS region
  }

  set {
    name  = "vpcId"
    value = data.terraform_remote_state.eks.outputs.vpc_id  # Replace with the VPC ID of your EKS cluster
  }

  # # Enable verbose logging
  # set {
  #   name  = "logLevel"
  #   value = "debug"
  # }

  depends_on = [ kubernetes_service_account.aws_load_balancer_controller_sa ]
}