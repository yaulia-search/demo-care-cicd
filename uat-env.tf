
# Public Subnet for Bastion
resource "aws_subnet" "bastion_public_subnet" {
    vpc_id = aws_vpc.custom_vpc.id 
    cidr_block = "172.16.13.0/24"
    availability_zone = "ap-southeast-1b"
    map_public_ip_on_launch = false

    tags = {
        Name = "PublicSubnet-Bastion-UAT "
    }
}

# Public Route Table
resource "aws_route_table" "bastion_rt" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_main.id
  }
}


# Public Route Table Associate
resource "aws_route_table_association" "bastion_rta" {
  subnet_id      = aws_subnet.bastion_public_subnet.id
  route_table_id = aws_route_table.bastion_rt.id
}


# Create Bastion Security Group
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.custom_vpc.id # Assuming you have a vpc defined

  ingress {
    description = "SSH access from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Consider restricting to your IP for security
  }

  ingress {
    description = "Allow ICMP (ping)"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}



# Create EC2 Bastion Jump Host
resource "aws_instance" "bastionHostInstance" {
  ami           = "ami-0b03299ddb99998e9"  # Replace with your desired AMI
  instance_type = "t3.micro" # Adjust instance type as needed
  subnet_id     = aws_subnet.bastion_public_subnet.id # Assuming you have a public subnet defined
  key_name      = "care_keypair" # Replace with your SSH key name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "bastion-host"
  }
}

#Elastic IP Provision 
resource "aws_eip" "bastion_eip" {
  domain = "vpc"
}

# Elastic IP Associate with Bastion Host
resource "aws_eip_association" "bastionEIPAssociate" {
  instance_id   = aws_instance.bastionHostInstance.id
  allocation_id = aws_eip.bastion_eip.id
}



#################################################

# Private Subnet
resource "aws_subnet" "private_01_uat_env" {
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = "172.16.15.0/24"
  availability_zone = "ap-southeast-1b" # Replace with your desired AZ
  tags = {
    Name = "private-subnet"
  }
}

resource "aws_security_group" "private_sg_uat_env" {
  name        = "private-sg"
  description = "Security group for private instances"
  vpc_id      = aws_vpc.custom_vpc.id

  # Add ingress rules as needed (e.g., allow traffic from other security groups)
  # Example: allow traffic from bastion
 
  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["172.16.0.0/16"] #Allow traffic inside the VPC
  }

  tags = {
    Name = "private-sg"
  }

  
}

resource "aws_route_table" "private_rt_uat_env" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private_rt_ass_uat_env" {
  subnet_id      = aws_subnet.private_01_uat_env.id
  route_table_id = aws_route_table.private_rt_uat_env.id
}



resource "aws_instance" "private" {
  ami           = "ami-0b03299ddb99998e9"  # Replace with your desired AMI
  instance_type = "t3.micro" # Adjust instance type as needed
  subnet_id     = aws_subnet.private_01_uat_env.id
  vpc_security_group_ids = [aws_security_group.private_sg_uat_env.id]
  key_name      = "care_keypair"

  tags = {
    Name = "WinServer-UAT-private-instance"
  }
  # Ensure the private instance is created after the bastion subnet
  depends_on = [aws_subnet.private_01_uat_env]
}


#################################################

resource "aws_subnet" "private_subnet_02_uat_env" {
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = "172.16.17.0/24"
  availability_zone = "ap-southeast-1b" # Replace with your desired AZ
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-az2"
  }
}

#RDS DB subnet Group
resource "aws_db_subnet_group" "rds_subnet_group_uat" {
  name       = "rds-subnet-group-uat"
  subnet_ids = [aws_subnet.private_subnet_02_uat_env.id, aws_subnet.private_subnet_01_prod.id]

  tags = {
    Name = "My DB subnet group"
  }
}

#Create Security Group for RDS 
resource "aws_security_group" "rds_sg_uat_env" {
  name        = "rds-sg-uat-env"
  description = "Security group for RDS SQL Server"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    from_port   = 1433 # SQL Server default port
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["172.16.0.0/16"]
    description = "SQL Server access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg-uat-env"
  }
}
#Instances RDS DB 
resource "aws_db_instance" "sql_server_instance" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "sqlserver-se" # Or sqlserver-se, web, etc.
  engine_version         = "15.00.4420.2.v1" # Replace with your desired version
  instance_class         = "db.m5.large" # Choose instance size
  license_model          = "license-included"
  #name                   = "mydb"
  username               = "admin"
  password               = "Admin12345" # Change this!
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group_uat.name
  vpc_security_group_ids = [aws_security_group.rds_sg_uat_env.id]
  skip_final_snapshot    = true
  multi_az               = false # Important for single AZ
  availability_zone      = "ap-southeast-1b" # Must match subnet
  publicly_accessible    = false # Important for private subnet
}


#Optional output
output "rds_endpoint" {
  value = aws_db_instance.sql_server_instance.endpoint
}

output "rds_port" {
  value = aws_db_instance.sql_server_instance.port
}

output "rds_instance_identifier" {
  value = aws_db_instance.sql_server_instance.identifier
}