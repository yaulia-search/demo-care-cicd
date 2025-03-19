terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0.1"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-southeast-1"
  alias = "Singapore-Region"
 
}

# Create a VPC
resource "aws_vpc" "custom_vpc" {
  cidr_block = "172.16.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true


 tags = {
    "Name" = "custom_vpc"
  } 
}
