resource "aws_vpc" "conductor_vpc" {
    cidr_block       =  var.vpc_cidr_block
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
        Name = "${var.vpc_tag_name}-${var.environment}"
    }
}
resource "aws_subnet" "conductor_public_subnet" {
    count =  var.number_of_public_subnets
    vpc_id = aws_vpc.conductor_vpc.id
    cidr_block = element(var.public_subnet_cidr_blocks, count.index)
    availability_zone = element(var.availability_zones, count.index)
    tags = {
        Name = "${var.public_subnet_tag_name}-${var.environment}"
    }         
}
resource "aws_subnet" "conductor_private_subnet" {
    count = var.number_of_private_subnets
    vpc_id =  aws_vpc.conductor_vpc.id
    cidr_block = element(var.private_subnet_cidr_blocks, count.index)
    availability_zone = element(var.availability_zones, count.index)

    tags = {
        Name = "${var.private_subnet_tag_name}-${var.environment}"
    }    
}
resource "aws_subnet" "conductor_private_subnet_db" {
    count = var.number_of_private_subnets_db
    vpc_id =  aws_vpc.conductor_vpc.id
    cidr_block = element(var.private_subnet_cidr_blocks_db, count.index)
    availability_zone = element(var.availability_zones, count.index)

    tags = {
        Name = "${var.private_subnet_tag_name}-db-${var.environment}"
    }    
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.conductor_vpc.id
}
resource "aws_eip" "elastic_ip" {
  count = var.number_of_public_subnets
  vpc = true
  tags = {
    Name = "elastic_ip-${count.index + 1}"
  }
}
resource "aws_nat_gateway" "conductor_nat" {
    allocation_id = aws_eip.elastic_ip[count.index].id
  count = var.number_of_public_subnets
  subnet_id = aws_subnet.conductor_public_subnet[count.index].id
  tags = {
    Name = "nat_gateway-${var.environment}"
  }
}
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.conductor_vpc.id
  count = var.number_of_public_subnets
  tags = {
    Name = "${aws_subnet.conductor_private_subnet[count.index].availability_zone}-route-table-public-${var.environment}"
  }
}
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.conductor_vpc.id
  count = var.number_of_private_subnets
  tags = {
    Name = "${aws_subnet.conductor_private_subnet[count.index].availability_zone}-route-table-NAT-${var.environment}"
  }
}
resource "aws_route_table" "private_route_table_db" {
  vpc_id = aws_vpc.conductor_vpc.id
  count = var.number_of_private_subnets_db
  tags = {
    Name = "${aws_subnet.conductor_private_subnet_db[count.index].availability_zone}-route-table-NAT-db-${var.environment}"
  }
}
resource "aws_route_table_association" "nat_private_subnet_db" {
  count = var.number_of_private_subnets_db
  route_table_id = aws_route_table.private_route_table_db[count.index].id
  subnet_id = aws_subnet.conductor_private_subnet_db[count.index].id
  }
resource "aws_route_table_association" "igw_public_subnet_assoc" {
  count = var.number_of_private_subnets
  route_table_id = aws_route_table.public_route_table[count.index].id
  subnet_id = aws_subnet.conductor_public_subnet[count.index].id 
  }
resource "aws_route_table_association" "nat_private_subnet_assoc" {
  count = var.number_of_private_subnets
  route_table_id = aws_route_table.private_route_table[count.index].id
  subnet_id = aws_subnet.conductor_private_subnet[count.index].id
  }
  resource "aws_route" "ig_public_subnet_route" {
  count = var.number_of_public_subnets
  route_table_id = aws_route_table.public_route_table[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.internet_gateway.id
}
resource "aws_route" "nat_private_subnet_route" {
  count = var.number_of_private_subnets
  route_table_id = aws_route_table.private_route_table[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.conductor_nat[count.index].id
}
