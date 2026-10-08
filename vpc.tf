# VPC
resource "aws_vpc" "devops-vpc" {
  cidr_block       = "11.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "My VPC"
  }
}

# Public Subnet 1
resource "aws_subnet" "pub_sub1" {
  vpc_id                  = aws_vpc.devops-vpc.id
  cidr_block              = "11.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"

  tags = {
    Name = "public subnet"
  }
}

# Public Subnet 2
resource "aws_subnet" "pub_sub2" {
  vpc_id                  = aws_vpc.devops-vpc.id
  cidr_block              = "11.0.3.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1b"

  tags = {
    Name = "public subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.devops-vpc.id

  tags = {
    Name = "My IGW"
  }
}

# Route Table
resource "aws_route_table" "route-table" {
  vpc_id = aws_vpc.devops-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "My RT"
  }
}

# Route Table Association 1
resource "aws_route_table_association" "rt-assoc-1" {
  subnet_id      = aws_subnet.pub_sub1.id
  route_table_id = aws_route_table.route-table.id
}

# Route Table Association 2
resource "aws_route_table_association" "rt-assoc-2" {
  subnet_id      = aws_subnet.pub_sub2.id
  route_table_id = aws_route_table.route-table.id
}

# Security Group
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.devops-vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

}
