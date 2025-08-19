# Part 2 Outputs - Updated for Simplified Architecture

# Output the Inspection Transit Gateway ID
output "inspection_transit_gateway_id" {
  description = "The ID of the Inspection Transit Gateway"
  value       = aws_ec2_transit_gateway.inspection_tg.id
}

# Output the East2 Transit Gateway ID
output "east2_transit_gateway_id" {
  description = "The ID of the East2 Transit Gateway"
  value       = aws_ec2_transit_gateway.east2_tg.id
}

# Output the Inspection VPC ID
output "inspection_vpc_id" {
  description = "The ID of the Inspection VPC"
  value       = aws_vpc.inspection_vpc.id
}

# Output the East2 VPC ID
output "east2_vpc_id" {
  description = "The ID of the East2 VPC"
  value       = aws_vpc.east2_vpc.id
}

# Output the Inspection Subnet IDs
output "inspection_subnet_1a_id" {
  description = "The ID of the inspection subnet in us-east-1a"
  value       = aws_subnet.inspection_subnet_1a.id
}

output "inspection_subnet_2a_id" {
  description = "The ID of the inspection subnet in us-east-2a"
  value       = aws_subnet.inspection_subnet_1b.id
}

# Output the East2 Private Subnet ID
output "east2_private_subnet_id" {
  description = "The ID of the private subnet in East2 VPC"
  value       = aws_subnet.east2_private_subnet.id
}

# Output the Inspection Appliance Instance IDs
output "inspection_appliance_1a_id" {
  description = "The ID of the inspection appliance in us-east-1a"
  value       = aws_instance.inspection_appliance_1a.id
}

output "inspection_appliance_2a_id" {
  description = "The ID of the inspection appliance in us-east-2a"
  value       = aws_instance.inspection_appliance_1b.id
}

# Output the East2 EC2 Instance ID
output "east2_ec2_instance_id" {
  description = "The ID of the EC2 instance in East2 VPC"
  value       = aws_instance.east2_ec2.id
}

# Output the East2 EC2 Instance Private IP
output "east2_ec2_private_ip" {
  description = "The private IP address of the EC2 instance in East2 VPC"
  value       = aws_instance.east2_ec2.private_ip
}

# Output the Cross-Region Peering Attachment ID
output "cross_region_peering_id" {
  description = "The ID of the cross-region Transit Gateway peering attachment"
  value       = aws_ec2_transit_gateway_peering_attachment.cross_region_peering.id
}

# Output the VPC Attachment IDs
output "inspection_tg_attachment_id" {
  description = "The ID of the inspection VPC attachment to inspection TGW"
  value       = aws_ec2_transit_gateway_vpc_attachment.inspection_tg_attachment.id
}

output "east2_vpc_attachment_id" {
  description = "The ID of the East2 VPC attachment to East2 TGW"
  value       = aws_ec2_transit_gateway_vpc_attachment.east2_vpc_attachment.id
}
