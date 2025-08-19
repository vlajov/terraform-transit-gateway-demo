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

variable "access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}

variable "key_name" {
  description = "Name of the AWS key pair for EC2 instances"
  type        = string
  default     = "Key pair name"
}

variable "iam_role_name" {
  description = "Name of the IAM role for EC2 instances"
  type        = string
  default     = "Role's name"
}