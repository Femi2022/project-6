# Aws vpc
resource "aws_vpc" "root-vpc" {
  cidr_block = var.cidr-block

  tags = {
    Name = "root-vpc"
  }
}

# Public subnet 1 
resource "aws_subnet" "web-subnet-1" {
  vpc_id     = aws_vpc.root-vpc.id
  cidr_block = var.public-subnet1-cidr
  availability_zone = var.AZ-1
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
  }
}

# Public subnet 2
resource "aws_subnet" "web-subnet-2" {
  vpc_id     = aws_vpc.root-vpc.id
  cidr_block = var.public-subnet2-cidr
  availability_zone = var.AZ-2 
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-2"
  }
}

# Private subnet 1
resource "aws_subnet" "application-subnet-1" {
  vpc_id     = aws_vpc.root-vpc.id
  cidr_block = var.private-subnet1-cidr
  availability_zone = var.AZ-1

  tags = {
    Name = "private-subnet-1"
  }
}

# Private subnet 2 
resource "aws_subnet" "application-subnet-2" {
  vpc_id     = aws_vpc.root-vpc.id
  cidr_block = var.private-subnet2-cidr
  availability_zone = var.AZ-2 

  tags = {
    Name = "private-subnet-2"
  }
}


# Private subnet 3
resource "aws_subnet" "eu-west-2a" {
  vpc_id     = aws_vpc.root-vpc.id
  cidr_block = var.private-subnet3-cidr
  availability_zone = var.AZ-1

  tags = {
    Name = "database-subnet-1"
  }
}

# Private subnet 4
resource "aws_subnet" "eu-west-2b" {
  vpc_id     = aws_vpc.root-vpc.id
  cidr_block = var.private-subnet4-cidr
  availability_zone = var.AZ-2

  tags = {
    Name = "database-subnet-2"
  }
}

# AWS internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.root-vpc.id

  tags = {
    Name = "aws-igw"
  }
}

# Public route table
resource "aws_route_table" "web-subnets-route-table" {
  vpc_id = aws_vpc.root-vpc.id

  tags = {
    Name = "web-subnets-route-table"
  }
}

# AWS route table association 1
resource "aws_route_table_association" "public-subnet-assoc-1" {
  subnet_id      = aws_subnet.web-subnet-1.id
  route_table_id = aws_route_table.web-subnets-route-table.id
}

# AWS route table association 2
resource "aws_route_table_association" "public-subnet-assoc-2" {
  subnet_id      = aws_subnet.web-subnet-2.id
  route_table_id = aws_route_table.web-subnets-route-table.id
}

# AWS route
resource "aws_route" "web-route" {
  route_table_id            = aws_route_table.web-subnets-route-table.id
  gateway_id                = aws_internet_gateway.igw.id
  destination_cidr_block    = "0.0.0.0/0"  
}

# AWS ec2 instance 1
resource "aws_instance" "webserver1" {
  ami           = "ami-064d33fad222a1c4a"
  instance_type = "t2.micro"
  availability_zone = "eu-west-2a"
  user_data = "install_apache.sh"
  tags = {
    Name = "webserver1"
  }
}

# AWS ec2 instance 2
resource "aws_instance" "webserver2" {
  ami           = "ami-064d33fad222a1c4a"
  instance_type = "t2.micro"
  availability_zone = "eu-west-2b"
  user_data = "install_apache.sh"

  tags = {
    Name = "webserver2"
  }
}

# AWS security group for webserver
resource "aws_security_group" "webserver-sg" {
  name        = "db-sg"
  description = "Enable HTTP access on port 80"
  vpc_id      = aws_vpc.root-vpc.id

  ingress {
    description      = "HTTP access"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "webserver-sg"
  }
}

# AWS security group for database
resource "aws_security_group" "db-sg" {
  name        = "db-sg"
  description = "Enable MYSQL Aurora access on port 3306"
  
  ingress {
    description      = "MYSQL/Aurora access"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "db-sg"
  }
}

# AWS application load balancer
resource "aws_lb" "traffic-alb" {
  name               = "traffic-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.webserver-sg.id]
  subnets            = [aws_subnet.web-subnet-1.id, aws_subnet.web-subnet-2.id]
}

# aws rds instance
resource "aws_db_instance" "db-project" {
  allocated_storage    = 12
  engine               = "mysql"
  engine_version       = "5.7"
  db_subnet_group_name =  aws_db_subnet_group.db-sub-group.name
  instance_class       = "db.t2.micro"
  multi_az             =  false
  username             = "pattern"
  password             = "school79"
  vpc_security_group_ids = [aws_security_group.webserver-sg.id]
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

# aws db subnet group
resource "aws_db_subnet_group" "db-sub-group" {
  name       = "db subnet group"

  subnet_ids = [
    aws_subnet.eu-west-2a.id,
    aws_subnet.eu-west-2b.id
  ]
   
  tags = {
    Name = "db subnetg"
 }
}
