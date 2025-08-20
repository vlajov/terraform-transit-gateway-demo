# AWS Transit Gateway Demo with Terraform

A comprehensive Terraform project demonstrating AWS Transit Gateway connectivity patterns, from basic VPC-to-VPC communication to advanced cross-region traffic inspection architecture.

## Project Overview

This project consists of two progressive parts that build upon each other:

- **Part 1**: Basic Transit Gateway connecting two VPCs in the same region
- **Part 2**: Advanced inspection VPC with cross-region connectivity and appliance mode

## Architecture

### Part 1: Basic Transit Gateway

- **First VPC** (10.0.0.0/24): Public VPC with internet gateway and EC2 instance
- **Second VPC** (20.0.0.0/24): Private VPC with EC2 instance
- **Transit Gateway**: Connects both VPCs for inter-VPC communication

### Part 2: Advanced Inspection Architecture

- **Inspection VPC** (30.0.0.0/24): Traffic inspection with appliance mode in us-east-1
- **East2 VPC** (40.0.0.0/24): Cross-region VPC in us-east-2
- **Multiple Transit Gateways**: Cross-region peering with traffic inspection flow

## Traffic Flow (Complete Architecture)

```
us-east-2 VPC → East2 TGW → Cross-Region Peering → Inspection TGW → Inspection VPC → Demo TGW → Original VPCs
```

## Prerequisites

- **AWS CLI** configured with appropriate credentials (access key and secret access key)
- **Terraform** v1.0 or later
- **AWS Account** with permissions to create VPCs, Transit Gateways, and EC2 instances
- **SSH Key Pairs** created in both us-east-1 and us-east-2 regions (for Part 2)

## Deployment

⚠️ **Important**: Part 2 depends on Part 1 infrastructure and **cannot be deployed independently**.

## Project Structure

```
terraform-transit-gateway-demo/
├── README.md                                          # This file
├── part-1-basic-tgw-with-two-vpcs/
│   ├── README.md                                      # Part 1 instructions
│   ├── main.tf                                        # Basic TGW infrastructure
│   ├── variables.tf                                   # Part 1 variables
│   ├── output.tf                                      # Part 1 outputs
│   └── terraform.tfvars                               # Part 1 configuration
└── part-2-inspection-vpc-and-cross-region-peering/
    ├── README.md                                      # Part 2 instructions
    ├── main.tf                                        # Advanced inspection architecture
    ├── variables.tf                                   # Part 2 variables
    ├── output.tf                                      # Part 2 outputs
    └── terraform.tfvars                               # Part 2 configuration
```

## Key Features

### Part 1 Features

- Basic Transit Gateway connectivity
- Public and private VPC setup
- Internet gateway for SSM accessibility
- Security groups for controlled access

### Part 2 Features

- **Appliance Mode**: Ensures AZ affinity for stateful security appliances
- **Cross-Region Connectivity**: us-east-2 VPC connects to East2 TGW, which peers with Inspection TGW via cross-region peering
- **Traffic Inspection**: All inter-region traffic passes through inspection appliances
- **Multi-AZ Deployment**: Inspection appliances across two availability zones
- **Complex Routing**: Custom route tables for traffic flow control

## Network Configuration

### CIDR Blocks

- **First VPC**: 10.0.0.0/24 (us-east-1)
- **Second VPC**: 20.0.0.0/24 (us-east-1)
- **Inspection VPC**: 30.0.0.0/24 (us-east-1) - Part 2 only
- **East2 VPC**: 40.0.0.0/24 (us-east-2) - Part 2 only

### Regions

- **Primary Region**: us-east-1
- **Secondary Region**: us-east-2 (Part 2 only)

## Cost Considerations

### Part 1 Costs

- 1 Transit Gateway
- 2 VPC attachments
- 2 EC2 t2.micro instances
- Standard data transfer charges

### Part 2 Additional Costs

- 2 additional Transit Gateways
- 1 cross-region Transit Gateway peering connection
- 2 additional VPC attachments
- 3 additional EC2 t2.micro instances
- Cross-region data transfer charges

## Testing

- **Part 1**: Inter-VPC communication through Transit Gateway
- **Part 2**: Cross-region traffic flow through inspection appliances

## Cleanup

⚠️ **Important**: Always destroy in reverse order (Part 2 before Part 1) due to dependencies.

## License

MIT License - see LICENSE file for details.
