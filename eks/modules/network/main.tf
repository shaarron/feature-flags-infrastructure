# Declare the data source
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  min_ha = min(length(data.aws_availability_zones.available.names), var.ha)
  total  = local.min_ha <= 1 ? 1 : local.min_ha
}


####### VPC part ####### 

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidrs
  enable_dns_hostnames = true
  tags = {
    Name = "${var.name_prefix}-VPC"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name_prefix}-IGW"
  }  
}

resource "aws_eip" "this" {
  domain = "vpc"
  tags = {
    Name = "${var.name_prefix}-EIP"
  }  
}

resource "aws_nat_gateway" "this" {
  subnet_id = aws_subnet.public[0].id
  allocation_id = aws_eip.this.id
  tags = {
    Name = "${var.name_prefix}-NAT-GW"
  }  
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = {
    Name = "${var.name_prefix}-PUBLIC-RTB"
  }  
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }
  tags = {
    Name = "${var.name_prefix}-PRIVATE-RTB"
  }  
}

resource "aws_subnet" "public" {
  count                   = local.total
  vpc_id                  = aws_vpc.this.id
  map_public_ip_on_launch = true
  cidr_block              = cidrsubnet(var.vpc_cidrs, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.name_prefix}-PUBLIC-SUBNET-${count.index}"
  }  
}

resource "aws_subnet" "private" {
  count                   = local.total
  vpc_id                  = aws_vpc.this.id
  map_public_ip_on_launch = false
  cidr_block              = cidrsubnet(var.vpc_cidrs, 8, count.index + local.total)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.name_prefix}-PRIVATE-SUBNET-${count.index}"
  }
}

resource "aws_route_table_association" "public" {
  count          = local.total
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = local.total
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}