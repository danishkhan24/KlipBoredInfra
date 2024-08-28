provider "aws" {
  region = "eu-west-2"
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

# Create a new VPC
resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "eks-fargate-vpc"
  }
}

# Create Public Subnets
resource "aws_subnet" "public_subnet" {
  count = 2
  vpc_id = aws_vpc.eks_vpc.id
  cidr_block = cidrsubnet(aws_vpc.eks_vpc.cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "eks-public-subnet-${count.index}"
    "kubernetes.io/role/elb" = "1"
  }
}

# Create Private Subnets
resource "aws_subnet" "private_subnet" {
  count = 2
  vpc_id = aws_vpc.eks_vpc.id
  cidr_block = cidrsubnet(aws_vpc.eks_vpc.cidr_block, 8, count.index + 2)
  map_public_ip_on_launch = false
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "eks-private-subnet-${count.index}"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = "eks-igw"
  }
}

# Create NAT Gateway
resource "aws_nat_gateway" "eks_nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.public_subnet[0].id
  tags = {
    Name = "eks-nat-gw"
  }
}

# Create Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  tags = {
    Name = "eks-nat-eip"
  }
}

# Create DynamoDB Endpoint
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.eks_vpc.id
  service_name = "com.amazonaws.${var.region}.dynamodb"
  
  vpc_endpoint_type = "Gateway"  # Specify the Gateway type
  
  route_table_ids = [
    aws_route_table.private_route_table.id
  ]

  tags = {
    Name = "dynamodb-endpoint"
  }
}


# Create Route Tables and Routes
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.eks_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }
  tags = {
    Name = "eks-public-rt"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.eks_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.eks_nat_gw.id
  }
  tags = {
    Name = "eks-private-rt"
  }
}

# Associate Route Tables with Subnets
resource "aws_route_table_association" "public_subnet_association" {
  count = 2
  subnet_id = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_subnet_association" {
  count = 2
  subnet_id = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

# Create Security Group
resource "aws_security_group" "eks_security_group" {
  vpc_id = aws_vpc.eks_vpc.id
  name_prefix = "eks-security-group-"
  description = "EKS Security Group"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-security-group"
  }
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "eksClusterRole"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "frontend-cluster"
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

# IAM Role for Fargate Pod Execution
resource "aws_iam_role" "fargate_pod_execution_role" {
  name = "eks-fargate-pod-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "eks-fargate-pod-execution-role"
  }
}

# Attach necessary policies to the role
resource "aws_iam_role_policy_attachment" "eks_fargate_execution_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate_pod_execution_role.name
}

resource "aws_iam_role_policy_attachment" "ecr_read_only_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.fargate_pod_execution_role.name
}


# EKS Fargate Profile for Application
resource "aws_eks_fargate_profile" "frontend_fargate_profile" {
  cluster_name           = aws_eks_cluster.eks_cluster.name
  fargate_profile_name   = "frontend-fargate-profile"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
  subnet_ids             = aws_subnet.private_subnet[*].id

  selector {
    namespace = "default"
    labels = {
      app = "frontend"
    }
  }
}

# EKS Fargate Profile for Application
resource "aws_eks_fargate_profile" "backend_fargate_profile" {
  cluster_name           = aws_eks_cluster.eks_cluster.name
  fargate_profile_name   = "backend_fargate_profile"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
  subnet_ids             = aws_subnet.private_subnet[*].id

  selector {
    namespace = "default"
    labels = {
      app = "backend"
    }
  }
}

# EKS Fargate Profile for System Pods
resource "aws_eks_fargate_profile" "system_fargate_profile" {
  cluster_name           = aws_eks_cluster.eks_cluster.name
  fargate_profile_name   = "system-fargate-profile"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
  subnet_ids             = aws_subnet.private_subnet[*].id

  selector {
    namespace = "kube-system"
  }
}
