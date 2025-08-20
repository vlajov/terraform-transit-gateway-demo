# Variables for Part 2 - Transit Gateway Appliance Mode

variable "region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "region_east2" {
  description = "Second region for cross-region VPC"
  type        = string
  default     = "us-east-2"
}

variable "key_name" {
  description = "Name of the AWS key pair for EC2 instances"
  type        = string
  default     = "Key pair name"
}
