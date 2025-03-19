# Create Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "nat-eip"
  }
}

# Create NAT Gateway
resource "aws_nat_gateway" "nat_gw_prod" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.NAT_public_subnet.id 
  #aws_subnet.public.id

  tags = {
    Name = "nat-gateway"
  }
  depends_on = [aws_internet_gateway.igw_main]
}

# Create Public Route Table
resource "aws_route_table" "public_nat_gw" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_main.id
  }

  tags = {
    Name = "public-route-table-nat-gw"
  }
}

# Associate Public Route Table with Public Subnet
resource "aws_route_table_association" "public_rta_nat_gw" {
  subnet_id      = aws_subnet.NAT_public_subnet.id
  route_table_id = aws_route_table.public_nat_gw.id
}

# Create Private Route Table
resource "aws_route_table" "private_rt_ec2_prod" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_prod.id
  }

  tags = {
    Name = "private-route-table"
  }
}

# Associate Private Route Table with Private Subnet
resource "aws_route_table_association" "private_rt_ass_prod_az1_env" {
  subnet_id      = aws_subnet.private_subnet_EC2_prod.id
  route_table_id = aws_route_table.private_rt_ec2_prod.id
}
