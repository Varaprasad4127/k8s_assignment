terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "backend-s3-delete-me"
    key            = "k8s/terraform.tfstate"
    region         = "ap-south-2"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}