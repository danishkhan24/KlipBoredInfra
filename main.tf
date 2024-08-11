# Fetch the default VPC
data "aws_vpc" "default" {
  default = true
}

# Fetch the subnets of the default VPC
data "aws_subnet" "default" {
  vpc_id = data.aws_vpc.default.id
}

# Create an EKS cluster with Fargate profiles
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "17.1.0"  # Ensure this is a valid version for your needs
  cluster_name    = "my-eks-cluster"
  cluster_version = "1.23"
  vpc_id          = data.aws_vpc.default.id

  # Pass the subnet IDs to the EKS module
  subnets = data.aws_subnet.default.ids

  # Fargate profiles configuration
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
