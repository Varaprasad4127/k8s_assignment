variable "aws_region" {
  description = "AWS region to deploy EC2"
  default     = "ap-south-2"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.medium"
}

variable "key_name" {
  description = "Name of the existing AWS key pair to use for SSH"
  type        = string
  default     = "test_key_pair_delete_me"
}

variable "vpc_id" {
  description = "VPC ID to deploy the EC2"
  type        = string
  default     = "vpc-0587f991eb9354461"
}

variable "subnet_id" {
  description = "Subnet ID to deploy the EC2"
  type        = string
  default     = "subnet-023dead10e4c67236"
}

variable "ami_id" {
  description = "AMI ID for Ubuntu 22.04"
  default     = "ami-01295e7cad1713e7a"
}

variable "public_key" {
  description = "public key"
  type        = string
  default     = null
}