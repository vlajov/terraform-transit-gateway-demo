# Part 2: Transit Gateway Appliance Mode Architecture
# This extends the original setup from Part 1 with inspection VPC and cross-region connectivity

# Default provider for us-east-1
provider "aws" {
  region = "us-east-1"
}

# Provider for us-east-2
provider "aws" {
  alias  = "east2"
  region = "us-east-2"
}

variable "key_name" {
  type        = string
  description = "Name of the SSH key pair to use for EC2 instances"
  sensitive   = true # Prevents the value from showing in logs
}

# Fetch latest Amazon Linux 2 AMI for us-east-1
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Fetch latest Amazon Linux 2 AMI for us-east-2
data "aws_ami" "amazon_linux_east2" {
  provider    = aws.east2
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Reference to original Transit Gateway from Part 1
data "aws_ec2_transit_gateway" "demo_tg" {
  filter {
    name   = "tag:Name"
    values = ["DemoTG"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
  filter {
    name   = "owner-id"
    values = [data.aws_caller_identity.current.account_id]
  }
}

# New Transit Gateway in us-east-1 with appliance mode
resource "aws_ec2_transit_gateway" "inspection_tg" {
  description                     = "TG for inspection with appliance mode"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  tags = {
    Name = "InspectionTG"
  }
}

# Inspection VPC in us-east-1
resource "aws_vpc" "inspection_vpc" {
  cidr_block           = "30.0.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "Inspection_VPC"
  }
}

# Inspection subnet in us-east-1a
resource "aws_subnet" "inspection_subnet_1a" {
  vpc_id            = aws_vpc.inspection_vpc.id
  cidr_block        = "30.0.0.0/26"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Inspection_subnet_1a"
  }
}

# Inspection subnet in us-east-1b (for appliance mode AZ requirement)
resource "aws_subnet" "inspection_subnet_1b" {
  vpc_id            = aws_vpc.inspection_vpc.id
  cidr_block        = "30.0.0.64/26"
  availability_zone = "us-east-1b"
  tags = {
    Name = "Inspection_subnet_1b"
  }
}

# Route table for Inspection VPC
resource "aws_route_table" "inspection_rt" {
  vpc_id = aws_vpc.inspection_vpc.id
  tags = {
    Name = "InspectionRT"
  }
}

# Associate inspection subnets with route table
resource "aws_route_table_association" "inspection_subnet_1a_association" {
  subnet_id      = aws_subnet.inspection_subnet_1a.id
  route_table_id = aws_route_table.inspection_rt.id
}

resource "aws_route_table_association" "inspection_subnet_1b_association" {
  subnet_id      = aws_subnet.inspection_subnet_1b.id
  route_table_id = aws_route_table.inspection_rt.id
}

# Security group for inspection appliances
resource "aws_security_group" "inspection_sg" {
  name        = "InspectionSG"
  description = "Security group for inspection appliances"
  vpc_id      = aws_vpc.inspection_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/24", "20.0.0.0/24", "40.0.0.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "InspectionSG"
  }
}

# Inspection appliance in us-east-1a
resource "aws_instance" "inspection_appliance_1a" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.inspection_sg.id]
  subnet_id              = aws_subnet.inspection_subnet_1a.id
  source_dest_check      = false
  tags = {
    Name = "Inspection_Appliance_1a"
  }
}

# Inspection appliance in us-east-1b
resource "aws_instance" "inspection_appliance_1b" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.inspection_sg.id]
  subnet_id              = aws_subnet.inspection_subnet_1b.id
  source_dest_check      = false
  tags = {
    Name = "Inspection_Appliance_1b"
  }
}

# New VPC in us-east-2
resource "aws_vpc" "east2_vpc" {
  provider             = aws.east2
  cidr_block           = "40.0.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "East2_VPC"
  }
}

# Private subnet in us-east-2a
resource "aws_subnet" "east2_private_subnet" {
  provider          = aws.east2
  vpc_id            = aws_vpc.east2_vpc.id
  cidr_block        = "40.0.0.0/25"
  availability_zone = "us-east-2a"
  tags = {
    Name = "East2_private_subnet"
  }
}

# Route table for us-east-2 VPC
resource "aws_route_table" "east2_rt" {
  provider = aws.east2
  vpc_id   = aws_vpc.east2_vpc.id
  tags = {
    Name = "East2RT"
  }
}

# Associate subnet with route table
resource "aws_route_table_association" "east2_subnet_association" {
  provider       = aws.east2
  subnet_id      = aws_subnet.east2_private_subnet.id
  route_table_id = aws_route_table.east2_rt.id
}

# Security group for EC2 in us-east-2
resource "aws_security_group" "east2_sg" {
  provider    = aws.east2
  name        = "East2SG"
  description = "Security group for East2 VPC"
  vpc_id      = aws_vpc.east2_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["20.0.0.0/24", "30.0.0.0/24"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["20.0.0.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "East2SG"
  }
}

# EC2 instance in us-east-2 (Third-party service simulation)
resource "aws_instance" "east2_ec2" {
  provider               = aws.east2
  ami                    = data.aws_ami.amazon_linux_east2.id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.east2_sg.id]
  subnet_id              = aws_subnet.east2_private_subnet.id
  tags = {
    Name = "East2_ThirdParty_Service"
  }
}

# Transit Gateway in us-east-2 for local VPC
resource "aws_ec2_transit_gateway" "east2_tg" {
  provider    = aws.east2
  description = "TG for East2 VPC"
  tags = {
    Name = "East2TG"
  }
}

# Attach East2VPC to East2TG
resource "aws_ec2_transit_gateway_vpc_attachment" "east2_vpc_attachment" {
  provider           = aws.east2
  transit_gateway_id = aws_ec2_transit_gateway.east2_tg.id
  vpc_id             = aws_vpc.east2_vpc.id
  subnet_ids         = [aws_subnet.east2_private_subnet.id]
  tags = {
    Name = "East2TG-East2VPC"
  }
}

# Attach Inspection VPC to Inspection TGW with appliance mode
resource "aws_ec2_transit_gateway_vpc_attachment" "inspection_tg_attachment" {
  transit_gateway_id     = aws_ec2_transit_gateway.inspection_tg.id
  vpc_id                 = aws_vpc.inspection_vpc.id
  subnet_ids             = [aws_subnet.inspection_subnet_1a.id, aws_subnet.inspection_subnet_1b.id]
  appliance_mode_support = "enable"
  tags = {
    Name = "InspectionTG-InspectionVPC"
  }
}

# Cross-region peering between TGWs
resource "aws_ec2_transit_gateway_peering_attachment" "cross_region_peering" {
  peer_transit_gateway_id = aws_ec2_transit_gateway.east2_tg.id
  transit_gateway_id      = aws_ec2_transit_gateway.inspection_tg.id
  peer_region             = "us-east-2"
  tags = {
    Name = "CrossRegion-TGW-Peering"
  }
}

# Accept the cross-region peering
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "cross_region_accepter" {
  provider                      = aws.east2
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.cross_region_peering.id
  tags = {
    Name = "CrossRegion-Peering-Accepter"
  }
}

# ===== ROUTE TABLES =====

# Route table for Inspection TGW
resource "aws_ec2_transit_gateway_route_table" "inspection_tg_rt" {
  transit_gateway_id = aws_ec2_transit_gateway.inspection_tg.id
  tags = {
    Name = "InspectionTG-RouteTable"
  }
}

# Associate Inspection VPC attachment with route table
resource "aws_ec2_transit_gateway_route_table_association" "inspection_vpc_association" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection_tg_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection_tg_rt.id
}

# Enable route propagation for Inspection VPC attachment
resource "aws_ec2_transit_gateway_route_table_propagation" "inspection_vpc_propagation" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection_tg_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection_tg_rt.id
}



# Associate cross-region peering with Inspection TGW route table
resource "aws_ec2_transit_gateway_route_table_association" "cross_region_peering_inspection_association" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.cross_region_peering.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection_tg_rt.id
  depends_on                     = [aws_ec2_transit_gateway_peering_attachment_accepter.cross_region_accepter]
}

# Associate Demo-to-Inspection peering with Inspection TGW route table
resource "aws_ec2_transit_gateway_route_table_association" "demo_peering_inspection_association" {
  transit_gateway_attachment_id  = local.peer_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection_tg_rt.id
}


# ===== ROUTING CONFIGURATION =====

# ROUTES IN INSPECTION TGW - Handle traffic between regions
resource "aws_ec2_transit_gateway_route" "inspection_to_east2" {
  destination_cidr_block         = "40.0.0.0/24"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.cross_region_peering.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection_tg_rt.id
  depends_on                     = [aws_ec2_transit_gateway_peering_attachment_accepter.cross_region_accepter, aws_ec2_transit_gateway_route_table_association.cross_region_peering_inspection_association]
}

# Routes from Inspection TGW back to Part 1 VPCs
resource "aws_ec2_transit_gateway_route" "inspection_to_first_vpc" {
  destination_cidr_block         = "10.0.0.0/24"
  transit_gateway_attachment_id  = local.peer_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection_tg_rt.id
  depends_on                     = [aws_ec2_transit_gateway_route_table_association.demo_peering_inspection_association]
}

resource "aws_ec2_transit_gateway_route" "inspection_to_second_vpc" {
  destination_cidr_block         = "20.0.0.0/24"
  transit_gateway_attachment_id  = local.peer_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection_tg_rt.id
  depends_on                     = [aws_ec2_transit_gateway_route_table_association.demo_peering_inspection_association]
}

# Route to Inspection VPC itself (for local traffic within inspection VPC)
resource "aws_ec2_transit_gateway_route" "inspection_to_inspection_vpc" {
  destination_cidr_block         = "30.0.0.0/24"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection_tg_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection_tg_rt.id
  depends_on                     = [aws_ec2_transit_gateway_route_table_association.inspection_vpc_association]
}

# ROUTES IN EAST2 TGW
resource "aws_ec2_transit_gateway_route" "east2_to_first_vpc" {
  provider                       = aws.east2
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.cross_region_peering.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.east2_tg.association_default_route_table_id
  depends_on                     = [aws_ec2_transit_gateway_peering_attachment_accepter.cross_region_accepter]
}

# VPC LEVEL ROUTES
# Routes in East2 VPC
resource "aws_route" "east2_default_route" {
  provider               = aws.east2
  route_table_id         = aws_route_table.east2_rt.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.east2_tg.id
}

# Routes in Inspection VPC
resource "aws_route" "inspection_to_first_vpc_route" {
  route_table_id         = aws_route_table.inspection_rt.id
  destination_cidr_block = "10.0.0.0/24"
  transit_gateway_id     = aws_ec2_transit_gateway.inspection_tg.id
}

resource "aws_route" "inspection_to_second_vpc_route" {
  route_table_id         = aws_route_table.inspection_rt.id
  destination_cidr_block = "20.0.0.0/24"
  transit_gateway_id     = aws_ec2_transit_gateway.inspection_tg.id
}

resource "aws_route" "inspection_to_east2_route" {
  route_table_id         = aws_route_table.inspection_rt.id
  destination_cidr_block = "40.0.0.0/24"
  transit_gateway_id     = aws_ec2_transit_gateway.inspection_tg.id
}

# ===== ROUTES FROM PART 1 ROUTE TABLES =====

# Get Part 1 PublicRT
data "aws_route_table" "public_rt" {
  filter {
    name   = "tag:Name"
    values = ["PublicRT"]
  }
}

# Get Part 1 PrivateRT
data "aws_route_table" "private_rt" {
  filter {
    name   = "tag:Name"
    values = ["PrivateRT"]
  }
}

# Routes from PublicRT to Inspection VPCs
resource "aws_route" "public_to_inspection_vpc" {
  route_table_id         = data.aws_route_table.public_rt.id
  destination_cidr_block = "30.0.0.0/24"
  transit_gateway_id     = data.aws_ec2_transit_gateway.demo_tg.id
}

# Override Part 1 specific route with default route
resource "aws_route" "second_vpc_route_to_first_vpc" {
  route_table_id         = data.aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = data.aws_ec2_transit_gateway.demo_tg.id
}

# ===== ROUTES IN DEMO TGW =====

# Route from Demo TGW to Inspection VPC
resource "aws_ec2_transit_gateway_route" "demo_to_inspection_vpc" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.demo_to_inspection_peering.id
  transit_gateway_route_table_id = data.aws_ec2_transit_gateway.demo_tg.association_default_route_table_id
  depends_on                     = [aws_ec2_transit_gateway_peering_attachment_accepter.demo_inspection_accepter]
}

# Create peering between Demo TGW and Inspection TGW
resource "aws_ec2_transit_gateway_peering_attachment" "demo_to_inspection_peering" {
  peer_transit_gateway_id = aws_ec2_transit_gateway.inspection_tg.id
  transit_gateway_id      = data.aws_ec2_transit_gateway.demo_tg.id
  peer_region             = "us-east-1"
  tags = {
    Name = "Demo-to-Inspection-Peering"
  }
}



# Find the peer-side attachment using a more reliable approach
data "aws_ec2_transit_gateway_peering_attachments" "all_inspection_peerings" {
  filter {
    name   = "transit-gateway-id"
    values = [aws_ec2_transit_gateway.inspection_tg.id]
  }
  depends_on = [aws_ec2_transit_gateway_peering_attachment.demo_to_inspection_peering]
}

# Accept the peering using the peer-side attachment
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "demo_inspection_accepter" {
  # Find the attachment that's not the cross-region one
  transit_gateway_attachment_id = [
    for id in data.aws_ec2_transit_gateway_peering_attachments.all_inspection_peerings.ids :
    id if id != aws_ec2_transit_gateway_peering_attachment.cross_region_peering.id
  ][0]
  tags = {
    Name = "Demo-Inspection-Accepter"
  }
}

# Local value - use accepter ID for route table associations on inspection TGW side
locals {
  peer_attachment_id = aws_ec2_transit_gateway_peering_attachment_accepter.demo_inspection_accepter.id
}
