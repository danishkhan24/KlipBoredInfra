provider "aws" {
  region = data.terraform_remote_state.eks.outputs.region
}

data "terraform_remote_state" "eks" {
  backend = "remote"
  config = {
    organization = "Klipbored"
    workspaces = {
      name = "EKS_Infrastructure"  # The EKS workspace name
    }
  }
}

# Fetch the AWS EKS token for authentication
data "aws_eks_cluster_auth" "eks_cluster_auth" {
  name = data.terraform_remote_state.eks.outputs.eks_cluster_name
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.eks.outputs.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.eks_cluster_certificate_authority)
  token                  = data.aws_eks_cluster_auth.eks_cluster_auth.token

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.eks.outputs.eks_cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.eks.outputs.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.eks_cluster_certificate_authority)
    token                  = data.aws_eks_cluster_auth.eks_cluster_auth.token

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.eks.outputs.eks_cluster_name]
      command     = "aws"
    }
  }
}

resource "kubernetes_namespace" "test" {
  metadata {
    name = "test-namespace"
  }
}

resource "kubernetes_service_account" "aws_load_balancer_controller_sa" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = data.terraform_remote_state.eks.outputs.eks_alb_role.arn
    }
  }

  depends_on = [ data.terraform_remote_state.eks ]
}