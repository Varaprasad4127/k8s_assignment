variable "aws_region" {
  description = "AWS region to deploy EC2"
  default     = "eu-central-1"
}

variable "aws_account_id" {
  description = "AWS account ID where the secret is stored"
  type        = string
  default     = "743298170833"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.large"
}

variable "vpc_id" {
  description = "VPC ID to deploy the EC2"
  type        = string
  default     = "vpc-09291e1d0efbbcd89"
}

variable "subnet_id" {
  description = "Subnet ID to deploy the EC2"
  type        = string
  default     = "subnet-012e778b96254cc52"
}

variable "ami_id" {
  description = "AMI ID for Ubuntu 22.04"
  default     = "ami-074dd8e8dac7651a5"
}

variable "public_key" {
  description = "public key"
  type        = string
  default     = null
}