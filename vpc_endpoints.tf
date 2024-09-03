# Create ECR Docker Endpoint
resource "aws_vpc_endpoint" "ecr_docker" {
  vpc_id            = aws_vpc.eks_vpc.id
  service_name      = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.private_subnet[*].id
  security_group_ids = [aws_security_group.eks_security_group.id]
}

# Create ECR API Endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = aws_vpc.eks_vpc.id
  service_name      = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.private_subnet[*].id
  security_group_ids = [aws_security_group.eks_security_group.id]
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