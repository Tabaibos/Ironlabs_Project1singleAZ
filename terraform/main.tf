# main.tf


#####   REGION ###################
provider "aws" {
  region = var.region
}

############### vpc #####################

resource "aws_vpc" "vpc_joaquim" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Project1-VPC-joaquim"
  }
}
################ SUBNETS ###################
resource "aws_subnet" "public_subnet-joaquim" {
  vpc_id                  = aws_vpc.vpc_joaquim.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone

  tags = {
    Name = "PublicSubnet-joaquim"
  }
}

resource "aws_subnet" "private_subnet-joaquim" {
  vpc_id                  = aws_vpc.vpc_joaquim.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = false
  availability_zone       = var.availability_zone

  tags = {
    Name = "PrivateSubnet-joaquim"
  }
}

resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.vpc_joaquim.default_route_table_id

  tags = {
    Name = "default-rt-unused"
  }
}

###################### NAT #############################
resource "aws_nat_gateway" "nat-joaquim" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet-joaquim.id
  depends_on    = [aws_internet_gateway.igw-joaquim]
}
resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw-joaquim]
}

############################ IGW #########################33
resource "aws_internet_gateway" "igw-joaquim" {
  vpc_id = aws_vpc.vpc_joaquim.id

  tags = {
    Name = "InternetGateway-joaquim"
  }
}
################# ROUTE TABLES ############################
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc_joaquim.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-joaquim.id
  }

  tags = {
    Name = "PublicRouteTable"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc_joaquim.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-joaquim.id
  }

  tags = {
    Name = "PrivateRouteTable"
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet-joaquim.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_rt_assoc" {
  subnet_id      = aws_subnet.private_subnet-joaquim.id
  route_table_id = aws_route_table.private_rt.id
}



############## SECURITY #############################
### preciso de especificar: VPC, SG entrada e saida depends_on


resource "aws_security_group" "sg_joaquim_front" {
  name        = "sg_joaquim_front_p1"
  description = "Allow SSH access from my IP and allow HTTP from all"
  vpc_id      = aws_vpc.vpc_joaquim.id

  ingress {
    description = "SSH from my ip"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.myIP] # defined in tfvars
  }

  ingress {
    description     = "ssh from sg_bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_bastion.id]
  }


  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_joaquim_front"
  }
}


resource "aws_security_group" "sg_joaquim_bck_app" {
  name        = "sg_joaquim_bck_app"
  description = "Allow SSH access from my IP and allow HTTP from all"
  vpc_id      = aws_vpc.vpc_joaquim.id
  depends_on  = [aws_security_group.sg_bastion]

  ingress {
    description = "SSH from my ip" #for testing purposes
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.myIP] # defined in tfvars
  }

  ingress {
    description     = "ssh from sg_bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_joaquim_back_app"
  }
}

resource "aws_security_group" "sg_bastion" {
  name        = "sg_bastion"
  description = "Allow SSH access from my IP and allow HTTP from all"
  vpc_id      = aws_vpc.vpc_joaquim.id


  ingress {
    description = "SSH from my ip" #for testing purposes
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.myIP] # defined in tfvars
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_joaquim_back_app"
  }
}

resource "aws_security_group" "sg_joaquim_bck_db" {
  name        = "sg_joaquim_bck_db"
  description = "Allow SSH access from my IP and allow HTTP from all"
  vpc_id      = aws_vpc.vpc_joaquim.id
  depends_on  = [aws_security_group.sg_joaquim_bck_app, aws_security_group.sg_bastion]

  ingress {
    description = "SSH from my ip" #for testing purposes
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.myIP] # defined in tfvars
  }

  ingress {
    description     = "ssh from sg_joaquim_front"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_joaquim_front.id]
  }

  ingress {
    description     = "ssh from sg_joaquim_bck_app"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_joaquim_bck_app.id]
  }

  ingress {
    description     = "ssh from sg_bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_joaquim_back_db"
  }
}

#--------------------------------------------------------------------------------------
## machines TEMPLATE
resource "aws_instance" "testing-front-joaquim" {
  ami                    = var.ami-image
  instance_type          = var.instance_type
  key_name               = var.key_name # defined in tfvars
  vpc_security_group_ids = [aws_security_group.sg_joaquim_front.id]
  subnet_id              = aws_subnet.public_subnet-joaquim.id

  tags = {
    Name = "joaquim-front-P1"
  }

}


resource "aws_instance" "testing-bck-joaquim-app" {
  ami                    = var.ami-image
  instance_type          = var.instance_type
  key_name               = var.key_name # defined in tfvars
  vpc_security_group_ids = [aws_security_group.sg_joaquim_bck_app.id]
  subnet_id              = aws_subnet.private_subnet-joaquim.id

  tags = {
    Name = "joaquim-bck-app-P1"
  }
}


resource "aws_instance" "testing-bck-joaquim-db" {
  ami                    = var.ami-image
  instance_type          = var.instance_type
  key_name               = var.key_name # defined in tfvars
  vpc_security_group_ids = [aws_security_group.sg_joaquim_bck_db.id]
  subnet_id              = aws_subnet.private_subnet-joaquim.id

  tags = {
    Name = "joaquim-bck-db-P1"
  }
}

resource "aws_instance" "bastion" {
  ami                    = var.ami-image
  instance_type          = var.instance_type
  key_name               = var.key_name # defined in tfvars
  vpc_security_group_ids = [aws_security_group.sg_bastion.id]
  subnet_id              = aws_subnet.public_subnet-joaquim.id

  tags = {
    Name = "joaquim-P1-bastion"
  }
}
