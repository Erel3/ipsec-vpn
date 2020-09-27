/*
* VPC
*
*/
resource "aws_vpc" "cluster-vpc" {
  cidr_block = var.aws_vpc_cidr_block

  tags = merge(var.default_tags, map(
    "Name", "${var.project_name}-vpc"
  ))
}

/*
* Subnets
*
*/
#public
resource "aws_subnet" "cluster-vpc-subnets-public" {
  vpc_id            = aws_vpc.cluster-vpc.id
  count             = length(var.aws_avail_zones)
  availability_zone = element(var.aws_avail_zones, count.index)
  cidr_block        = element(var.aws_cidr_subnets_public, count.index)

  tags = merge(var.default_tags, map(
    "Name", "${var.project_name}-${element(var.aws_avail_zones, count.index)}-public"
  ))
}
#private
resource "aws_subnet" "cluster-vpc-subnets-private" {
  vpc_id            = aws_vpc.cluster-vpc.id
  count             = var.aws_without_private ? 0 : length(var.aws_avail_zones)
  availability_zone = element(var.aws_avail_zones, count.index)
  cidr_block        = element(var.aws_cidr_subnets_private, count.index)

  tags = merge(var.default_tags, map(
    "Name", "${var.project_name}-${element(var.aws_avail_zones, count.index)}-private"
  ))
}

/*
* Routing
*
*/
#public
resource "aws_internet_gateway" "cluster-vpc-internetgw" {
  vpc_id = aws_vpc.cluster-vpc.id

  tags = merge(var.default_tags, map(
    "Name", "${var.project_name}-internetgw"
  ))
}
resource "aws_route_table" "routetable-public" {
  vpc_id = aws_vpc.cluster-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cluster-vpc-internetgw.id
  }

  tags = merge(var.default_tags, map(
    "Name", "${var.project_name}-routetable-public"
  ))
}
resource "aws_route_table_association" "routetable-public" {
  count          = length(var.aws_cidr_subnets_public)
  subnet_id      = element(aws_subnet.cluster-vpc-subnets-public.*.id, count.index)
  route_table_id = aws_route_table.routetable-public.id
}

#private
resource "aws_eip" "cluster-nat-eip" {
  count = var.aws_without_private ? 0 : length(var.aws_cidr_subnets_public)
  vpc   = true
}
resource "aws_nat_gateway" "cluster-nat-gateway" {
  count         = var.aws_without_private ? 0 : length(var.aws_cidr_subnets_public)
  allocation_id = element(aws_eip.cluster-nat-eip.*.id, count.index)
  subnet_id     = element(aws_subnet.cluster-vpc-subnets-public.*.id, count.index)
}
resource "aws_route_table" "routetable-private" {
  count  = var.aws_without_private ? 0 : length(var.aws_cidr_subnets_private)
  vpc_id = aws_vpc.cluster-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.cluster-nat-gateway.*.id, count.index)
  }

  tags = merge(var.default_tags, map(
    "Name", "${var.project_name}-routetable-private-${count.index}"
  ))
}
resource "aws_route_table_association" "routetable-private" {
  count          = var.aws_without_private ? 0 : length(var.aws_cidr_subnets_private)
  subnet_id      = element(aws_subnet.cluster-vpc-subnets-private.*.id, count.index)
  route_table_id = element(aws_route_table.routetable-private.*.id, count.index)
}
