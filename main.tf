# Fetch the default VPC
data "aws_vpc" "default" {
  default = true
}

# Fetch the subnets of the default VPC
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

# Fetch the subnets' details
data "aws_subnets" "default" {
  ids = data.aws_subnet_ids.default.ids
}

# Create an EKS cluster with Fargate profiles
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "my-eks-cluster"
  cluster_version = "1.23"
  vpc_id          = data.aws_vpc.default.id

  # Specify the subnets where the EKS cluster should run
  subnet_ids = data.aws_subnet_ids.default.ids

  fargate_profiles = {
    fargate = {
      name = "fargate-profile"
      selectors = [
        {
          namespace = "default"
        },
        {
          namespace = "kube-system"
        }
      ]
    }
  }

  manage_aws_auth = true
}

# Output the EKS cluster endpoint
output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_id
}
