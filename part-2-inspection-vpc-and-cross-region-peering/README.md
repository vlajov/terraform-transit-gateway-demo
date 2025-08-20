# Part 2: Advanced Transit Gateway with Inspection VPC

Advanced Terraform configuration extending Part 1 with cross-region connectivity and traffic inspection architecture, as described in my [LinkedIn article]().

## Files

- main.tf: Defines inspection VPC, cross-region setup, and multiple Transit Gateways.
- variables.tf: Variable definitions for Part 2 configuration.
- output.tf: Outputs resource IDs and IPs for Part 2 resources.
- terraform.tfvars: Configuration values for regions and key pairs.

## Usage

1. **Deploy [Part 1](https://www.linkedin.com/pulse/connect-two-aws-vpcs-terraform-transit-gateway-guide-jovanovski-pte0f/?trackingId=T8jVXOI%2FAReIQOSOqyRO%2Bg%3D%3D) first** - Part 2 cannot be deployed independently.
2. Follow the LinkedIn article for detailed setup instructions.
3. Update terraform.tfvars with your key pair name (must exist in both us-east-1 and us-east-2).
4. Run terraform init, terraform plan, and terraform apply.

## Requirements

- **Part 1 successfully deployed** and Transit Gateway "DemoTG" available
- Terraform v1.0 or later
- AWS CLI configured with credentials
- Key pair in us-east-1 region (can reuse from Part 1)
- Key pair in us-east-2 region (new requirement)
- Multi-region permissions in AWS account

## Architecture

- **Inspection VPC** (30.0.0.0/24): Traffic inspection with appliance mode in us-east-1
- **East2 VPC** (40.0.0.0/24): Cross-region VPC in us-east-2
- **3 Transit Gateways**: Demo TGW, Inspection TGW, and East2 TGW
- **Cross-region peering**: Between Inspection TGW and East2 TGW
- **Traffic flow**: All inter-region traffic passes through inspection appliances
  _steps explained in the LinkedIn article_
