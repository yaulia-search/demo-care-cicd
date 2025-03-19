# Public Subnet for NAT Production #######################

resource "aws_public" "NAT_public_subnet" {
    vpc_id = aws_vpc.custom_vpc.id 
    cidr_block = "172.16.1.0/24"
    availability_zone = "ap-southeast-1a"
    map_public_ip_on_launch = true

    tags = {
        Name = "PublicSubnet-NAT-Prod"
    }
}



# Private Subnet for EC2 Production #######################

resource "aws_subnet" "private_subnet_EC2_prod" {
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = "172.16.3.0/24" 
  availability_zone = "ap-southeast-1a" 
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-az1"
  }
}


# Public Subnet for RDS Production #######################

resource "aws_subnet" "private_rds" {
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = "172.16.5.0/24"
  availability_zone = "ap-southeast-1a"
}
