
##########################################################
        # Collecting Avialabilty Zones 
##########################################################

data "aws_availability_zones" "az" {
  state = "available"
}


##########################################################
        # VPC Creation 
##########################################################

resource "aws_vpc" "main" {
  cidr_block            = var.vpc_cidr
  instance_tenancy      = "default"
  enable_dns_support    = "true"
  enable_dns_hostnames  = "true"

  tags                  = {
    Name                = "${var.project}-vpc"
  }
}



##########################################################
        # Internet GateWay Creation 
##########################################################

resource "aws_internet_gateway" "igw" {
  vpc_id    = aws_vpc.main.id

  tags      = {
    Name    = "${var.project}-igw"
  }
}


##########################################################
        # Public Subnet - 1 
##########################################################

resource "aws_subnet" "public1" {
  vpc_id                            = aws_vpc.main.id
  cidr_block                        = cidrsubnet(var.vpc_cidr,var.subnetcidr,0)
  availability_zone                 = data.aws_availability_zones.az.names[0]
  map_public_ip_on_launch           = true 
  tags                              = {
    Name                            = "${var.project}-public1"
  }
}


##########################################################
        # Public Subnet - 2 
##########################################################

resource "aws_subnet" "public2" {
  vpc_id                            = aws_vpc.main.id
  cidr_block                        = cidrsubnet(var.vpc_cidr,var.subnetcidr,1)
  availability_zone                 = data.aws_availability_zones.az.names[1]
  map_public_ip_on_launch           = true 
  tags                              = {
    Name                            = "${var.project}-public2"
  }
}


##########################################################
        # Public Subnet - 3 
##########################################################

resource "aws_subnet" "public3" {
  vpc_id                            = aws_vpc.main.id
  cidr_block                        = cidrsubnet(var.vpc_cidr,var.subnetcidr,2)
  availability_zone                 = data.aws_availability_zones.az.names[2]
  map_public_ip_on_launch           = true 
  tags                              = {
    Name                            = "${var.project}-public3"
  }
}


##########################################################
        # Private Subnet - 1
##########################################################

resource "aws_subnet" "private1" {
  vpc_id                            = aws_vpc.main.id
  cidr_block                        = cidrsubnet(var.vpc_cidr,var.subnetcidr,3)
  availability_zone                 = data.aws_availability_zones.az.names[0]
  tags                              = {
    Name                            = "${var.project}-private1"
  }
}


##########################################################
        # Private Subnet - 2
##########################################################

resource "aws_subnet" "private2" {
  vpc_id                            = aws_vpc.main.id
  cidr_block                        = cidrsubnet(var.vpc_cidr,var.subnetcidr,4)
  availability_zone                 = data.aws_availability_zones.az.names[1]
  tags                              = {
    Name                            = "${var.project}-private2"
  }
}

##########################################################
        # Private Subnet - 3
##########################################################

resource "aws_subnet" "private3" {
  vpc_id                            = aws_vpc.main.id
  cidr_block                        = cidrsubnet(var.vpc_cidr,var.subnetcidr,5)
  availability_zone                 = data.aws_availability_zones.az.names[2]
  tags                              = {
    Name                            = "${var.project}-private3"
  }
}



##########################################################
        # Route Table Public
##########################################################

resource "aws_route_table" "route-public" {
  vpc_id            = aws_vpc.main.id
  route {
      cidr_block    = "0.0.0.0/0"
      gateway_id    = aws_internet_gateway.igw.id
  }
  tags = {
      Name          = "${var.project}-public"
  }
  }

########################################################## 
        # Route Table Association Public 
##########################################################

  resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.route-public.id
}

  resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.route-public.id
}

  resource "aws_route_table_association" "public3" {
  subnet_id      = aws_subnet.public3.id
  route_table_id = aws_route_table.route-public.id
}


##########################################################
        # Elastic IP 
##########################################################

resource "aws_eip" "eip" {
  vpc      = true
  tags     = {
    Name   = "${var.project}-eip"
  }
}


##########################################################
        # Nat GateWay 
##########################################################

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public2.id

  tags = {
    Name = "${var.project}-nat"
  }
}

##########################################################
        # Route Table Private
##########################################################

resource "aws_route_table" "route-private" {
  vpc_id            = aws_vpc.main.id
  route {
      cidr_block    = "0.0.0.0/0"
      gateway_id    = aws_nat_gateway.nat.id
  }
  tags = {
      Name          = "${var.project}-private"
  }
  }

########################################################## 
        # Route Table Association Private 
##########################################################

  resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.route-private.id
}

  resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.route-private.id
}

  resource "aws_route_table_association" "private3" {
  subnet_id      = aws_subnet.private3.id
  route_table_id = aws_route_table.route-private.id
}




