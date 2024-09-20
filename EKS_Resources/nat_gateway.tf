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