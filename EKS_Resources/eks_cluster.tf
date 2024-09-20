# EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = aws_subnet.private_subnet[*].id
    security_group_ids = [aws_security_group.eks_security_group.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_service_policy,
  ]
}

# EKS Fargate Profile for Application
resource "aws_eks_fargate_profile" "dev_fargate_profile" {
  cluster_name           = aws_eks_cluster.eks_cluster.name
  fargate_profile_name   = "dev-fargate-profile"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
  subnet_ids             = aws_subnet.private_subnet[*].id

  selector {
    namespace = "default"
    labels = {
      app = "frontend"
    }
  }

  selector {
    namespace = "default"
    labels = {
      app = "backend"
    }
  }

  selector {
    namespace = "default"
    labels = {
      app = "prometheus"
    }
  }

  selector {
    namespace = "kube-system"
  }
}

# # EKS Fargate Profile for Application
# resource "aws_eks_fargate_profile" "backend_fargate_profile" {
#   cluster_name           = aws_eks_cluster.eks_cluster.name
#   fargate_profile_name   = "backend_fargate_profile"
#   pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
#   subnet_ids             = aws_subnet.private_subnet[*].id

#   selector {
#     namespace = "default"
#     labels = {
#       app = "backend"
#     }
#   }
# }

# # EKS Fargate Profile for System Pods
# resource "aws_eks_fargate_profile" "system_fargate_profile" {
#   cluster_name           = aws_eks_cluster.eks_cluster.name
#   fargate_profile_name   = "system-fargate-profile"
#   pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
#   subnet_ids             = aws_subnet.private_subnet[*].id

#   selector {
#     namespace = "kube-system"
#   }
# }

# # EKS Fargate Profile for Monitoring
# resource "aws_eks_fargate_profile" "monitoring_fargate_profile" {
#   cluster_name           = aws_eks_cluster.eks_cluster.name
#   fargate_profile_name   = "monitoring-fargate-profile"
#   pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
#   subnet_ids             = aws_subnet.private_subnet[*].id

#   selector {
#     namespace = "default"
#     labels = {
#       app = "prometheus"
#     }
#   }
# }
