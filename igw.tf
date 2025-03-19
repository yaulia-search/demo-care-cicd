# Create Internet Gateway 
resource "aws_internet_gateway" "igw_main" {

    vpc_id = aws_vpc.custom_vpc.id
    
    tags = {
        "Name" = "igw_main"
    }
 }