data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  min_az   = min(length(data.aws_availability_zones.available.names), var.availability_zones)
  total    = local.min_az <= 1 ? 1 : local.min_az
  az_names = toset(slice(data.aws_availability_zones.available.names, 0, local.total))
  az_list  = slice(data.aws_availability_zones.available.names, 0, local.total)
}

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
  for_each = var.single_nat_gateway ? toset([local.az_list[0]]) : local.az_names
  domain   = "vpc"
  tags = {
    Name = "${var.name_prefix}-EIP-${each.key}"
  }
}

resource "aws_nat_gateway" "this" {
  for_each      = var.single_nat_gateway ? toset([local.az_list[0]]) : local.az_names
  subnet_id     = aws_subnet.public[each.key].id
  allocation_id = aws_eip.this[each.key].id
  tags = {
    Name = "${var.name_prefix}-NAT-GW-${each.key}"
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
  for_each = local.az_names
  vpc_id   = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[var.single_nat_gateway ? local.az_list[0] : each.key].id
  }
  tags = {
    Name = "${var.name_prefix}-PRIVATE-RTB-${each.key}"
  }
}

resource "aws_subnet" "public" {
  for_each                = local.az_names
  vpc_id                  = aws_vpc.this.id
  map_public_ip_on_launch = true
  cidr_block              = cidrsubnet(var.vpc_cidrs, 8, index(local.az_list, each.key))
  availability_zone       = each.key
  tags = {
    Name                     = "${var.name_prefix}-PUBLIC-SUBNET-${each.key}"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "private" {
  for_each                = local.az_names
  vpc_id                  = aws_vpc.this.id
  map_public_ip_on_launch = false
  cidr_block              = cidrsubnet(var.vpc_cidrs, 8, index(local.az_list, each.key) + local.total)
  availability_zone       = each.key
  tags = {
    Name                              = "${var.name_prefix}-PRIVATE-SUBNET-${each.key}"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_route_table_association" "public" {
  for_each       = local.az_names
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each       = local.az_names
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}
