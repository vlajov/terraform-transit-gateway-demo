# Terraform and Transit Gateway Demo

Terraform configuration for connecting two AWS VPCs using a Transit Gateway, as described in my [LinkedIn article](https://www.linkedin.com/pulse/connect-two-aws-vpcs-terraform-transit-gateway-guide-jovanovski-pte0f/?trackingId=RZfA4FnTRC%2BsGqjIFmL33g%3D%3D).

## Files

- main.tf: Defines VPCs, EC2 instances, and Transit Gateway.
- output.tf: Outputs resource IDs and IPs.
- .gitignore: Excludes Terraform state files and sensitive data.

## Usage

1. Follow my [LinkedIn article](https://www.linkedin.com/pulse/connect-two-aws-vpcs-terraform-transit-gateway-guide-jovanovski-pte0f/?trackingId=RZfA4FnTRC%2BsGqjIFmL33g%3D%3D) to set up IAM role and a key pair.
2. Download main.tf and output.tf from this repository.
3. Update main.tf with your values for key_name = "Key's name" (lines 84 & 154) and iam_instance_profile = "Role's name" (line 87).
4. Run terraform init, terraform plan, and terraform apply.

## Requirements

- Setup Visual Studio Code
- Terraform v1.0 or later
- AWS account with console login ability
- IAM role named "Role's name" with AmazonSSMManagedInstanceCore policy
