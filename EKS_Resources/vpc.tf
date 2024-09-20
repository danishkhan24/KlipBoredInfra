# Create a new VPC
resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "klipbored-vpc"
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