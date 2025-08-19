# Part 2: Transit Gateway Appliance Mode Architecture

This extends the original Transit Gateway demo with an advanced appliance mode architecture for traffic inspection.

## Architecture Overview

**Part 2 adds:**
- New Transit Gateway in us-east-1 with appliance mode enabled
- Inspection VPC in us-east-1 with security appliances in multiple AZs
- New VPC in us-east-2 that connects cross-region to the inspection TGW
- Transit Gateway peering between the new and original TGWs
- Custom route tables for traffic inspection flow

## Traffic Flow

```
us-east-2 VPC → Inspection TGW (us-east-1) → Inspection VPC → Original TGW → Original VPCs
```

## Key Features

1. **Appliance Mode**: Ensures strict AZ affinity for stateful security appliances
2. **Cross-Region Connectivity**: us-east-2 VPC connects directly to us-east-1 TGW
3. **Traffic Inspection**: All traffic between regions passes through inspection appliances
4. **Multi-AZ Deployment**: Inspection appliances in both us-east-1a and us-east-1b

## Files

- `main-part2.tf`: Main infrastructure configuration for Part 2
- `output-part2.tf`: Outputs for all Part 2 resources
- `variables-part2.tf`: Variable definitions for Part 2
- `README-part2.md`: This documentation

## Prerequisites

1. Complete Part 1 deployment (original main.tf and output.tf)
2. AWS credentials configured
3. Key pair created in both us-east-1 and us-east-2
4. IAM role with AmazonSSMManagedInstanceCore policy

## Deployment Steps

1. **Update Variables**: Edit the key pair names and IAM role in `main-part2.tf`:
   - Line 85, 95: Update `key_name = "Your-Key-Pair-Name"`
   - Line 125: Update `key_name = "Your-Key-Pair-Name-East2"`

2. **Initialize Terraform** (if not already done):
   ```bash
   terraform init
   ```

3. **Plan the deployment**:
   ```bash
   terraform plan -var="access_key=YOUR_ACCESS_KEY" -var="secret_key=YOUR_SECRET_KEY"
   ```

4. **Apply the configuration**:
   ```bash
   terraform apply -var="access_key=YOUR_ACCESS_KEY" -var="secret_key=YOUR_SECRET_KEY"
   ```

## Network Configuration

### VPC CIDR Blocks
- Original First VPC: `10.0.0.0/24`
- Original Second VPC: `20.0.0.0/24`
- **New Inspection VPC**: `30.0.0.0/24`
- **New East2 VPC**: `40.0.0.0/24`

### Subnets
- Inspection subnet 1a: `30.0.0.0/26` (us-east-1a)
- Inspection subnet 1b: `30.0.0.64/26` (us-east-1b)
- East2 private subnet: `40.0.0.0/25` (us-east-2a)

## Security Groups

- **Inspection SG**: Allows traffic from all VPCs (10.0.0.0/24, 20.0.0.0/24, 40.0.0.0/24)
- **East2 SG**: Allows SSH from original VPCs and inspection VPC

## Important Notes

1. **Appliance Mode**: Enabled on the inspection VPC attachment to ensure AZ stickiness
2. **Source/Dest Check**: Disabled on inspection appliances for traffic forwarding
3. **Cross-Region**: us-east-2 VPC directly attaches to us-east-1 TGW (no local TGW needed)
4. **Route Tables**: Custom route tables control traffic flow through inspection appliances

## Testing Connectivity

### Connectivity Scenario
The architecture simulates a real-world scenario where:
- **Private instance in us-east-1** (Second VPC) needs to access a third-party service
- **Third-party service in us-east-2** (East2 VPC) - private instance with no public IP
- **All cross-region traffic** must pass through inspection appliances for security

### Testing Steps
1. **Connect to the public instance** in First VPC (us-east-1) via SSH
2. **From the public instance**, SSH to the private instance in Second VPC (20.0.0.0/24)
3. **From the private instance**, test connectivity to the East2 service (40.0.0.0/24)
4. **Verify traffic flow**: East2 → Inspection TGW → Inspection VPC → Original TGW → Second VPC

### Test Commands
```bash
# From Second VPC private instance, test connectivity to East2 service
ping <east2_private_ip>
ssh ec2-user@<east2_private_ip>

# Check routing
ip route
traceroute <east2_private_ip>
```

### Expected Traffic Flow
```
Second VPC (us-east-1) ↔ East2 VPC (us-east-2)
     ↓                           ↑
Original TGW ←→ TGW Peering ←→ Inspection TGW
                    ↓
              Inspection VPC
           (Traffic inspection)
```

## Cleanup

To destroy Part 2 resources:
```bash
terraform destroy -target=aws_ec2_transit_gateway_peering_attachment.tg_peering
terraform destroy -var="access_key=YOUR_ACCESS_KEY" -var="secret_key=YOUR_SECRET_KEY"
```

## Cost Considerations

Part 2 adds:
- 1 additional Transit Gateway
- 1 Transit Gateway peering connection
- 2 additional VPC attachments (including cross-region)
- 3 additional EC2 instances
- Cross-region data transfer charges