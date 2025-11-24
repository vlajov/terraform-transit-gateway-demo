# Configuring the AWS provider with region
provider "aws" {
}

# Fetch the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Create first VPC
resource "aws_vpc" "first_vpc" {
  cidr_block           = "10.0.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "First_VPC"
  }
}

# Create public subnet in the first vpc
resource "aws_subnet" "public_subnet_first_vpc" {
  vpc_id            = aws_vpc.first_vpc.id
  cidr_block        = "10.0.0.0/25"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Public_subnet_first_VPC"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.first_vpc.id
  tags = {
    Name = "IGW for TG demo"
  }
}

# Create Public Route table and attach to internet gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.first_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "PublicRT"
  }
}

# Associate the Public subnet with the public route table
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet_first_vpc.id
  route_table_id = aws_route_table.public_rt.id
}

# Create Security group for EC2 in First_VPC
resource "aws_security_group" "ec2sg" {
  name        = "FirstEC2_sg"
  description = "SG1 for TG demo"
  vpc_id      = aws_vpc.first_vpc.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "FirstEC2_sg"
  }
}

# Create an EC2 in First VPC 
resource "aws_instance" "first_vpc_ec2" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  key_name                    = "YOUR KEY PAIRS NAME" # Make sure you use the Key pair name that you created in Task 5
  vpc_security_group_ids      = [aws_security_group.ec2sg.id]
  subnet_id                   = aws_subnet.public_subnet_first_vpc.id
  iam_instance_profile        = "YOUR IAM ROLE" # Use the Role’s name from Task 1
  associate_public_ip_address = true
  tags = {
    Name = "First_VPC_EC2"
  }
}

# Create Second VPC
resource "aws_vpc" "second_vpc" {
  cidr_block           = "20.0.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "Second_VPC"
  }
}

# Create private subnet in Second VPC
resource "aws_subnet" "private_subnet_second_vpc" {
  vpc_id            = aws_vpc.second_vpc.id
  cidr_block        = "20.0.0.0/25"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Private_subnet_second_VPC"
  }
}

# Create Private Route table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.second_vpc.id
  tags = {
    Name = "PrivateRT"
  }
}

# Associate the Private subnet with the private route table
resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.private_subnet_second_vpc.id
  route_table_id = aws_route_table.private_rt.id
}

# Create Security group for EC2 in Second_VPC
resource "aws_security_group" "privateec2sg" {
  name        = "SecondEC2_sg"
  description = "SG2 for TG demo"
  vpc_id      = aws_vpc.second_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.first_vpc.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "SecondEC2_sg"
  }
}

# Create an EC2 in Second VPC 
resource "aws_instance" "second_vpc_ec2" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  key_name                    = "YOUR KEY PAIRS NAME" # Make sure you use the Key pair name that you created in Task 5
  vpc_security_group_ids      = [aws_security_group.privateec2sg.id]
  subnet_id                   = aws_subnet.private_subnet_second_vpc.id
  associate_public_ip_address = false
  tags = {
    Name = "Second_VPC_EC2"
  }
}

# Create a Transit Gateway
resource "aws_ec2_transit_gateway" "demo_tg" {
  description = "TG demo for connecting VPCs"
  tags = {
    Name = "DemoTG"
  }
}

# Create two Transit gateway attachments for the VPCs
resource "aws_ec2_transit_gateway_vpc_attachment" "first_vpc_tga" {
  transit_gateway_id = aws_ec2_transit_gateway.demo_tg.id
  vpc_id             = aws_vpc.first_vpc.id
  subnet_ids         = [aws_subnet.public_subnet_first_vpc.id]
  depends_on         = [aws_vpc.first_vpc, aws_subnet.public_subnet_first_vpc]
  tags = {
    Name = "FirstVPC-DemoTG"
  }
}
resource "aws_ec2_transit_gateway_vpc_attachment" "second_vpc_tga" {
  transit_gateway_id = aws_ec2_transit_gateway.demo_tg.id
  vpc_id             = aws_vpc.second_vpc.id
  subnet_ids         = [aws_subnet.private_subnet_second_vpc.id]
  depends_on         = [aws_vpc.second_vpc, aws_subnet.private_subnet_second_vpc]
  tags = {
    Name = "SecondVPC-DemoTG"
  }
}

# Tag the default DemoTG route table
resource "aws_ec2_tag" "demo_tg_default_rt_name" {
  resource_id = aws_ec2_transit_gateway.demo_tg.association_default_route_table_id
  key         = "Name"
  value       = "DemoTG-RT"
}

# Add the routes in the DemoTG route tables
resource "aws_route" "first_vpc_route_to_second_vpc" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = aws_vpc.second_vpc.cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.demo_tg.id
}
resource "aws_route" "second_vpc_route_to_first_vpc" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = aws_vpc.first_vpc.cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.demo_tg.id
}
