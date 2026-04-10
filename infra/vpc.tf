resource "aws_vpc" "main" {
  cidr_block = "172.31.0.0/16"
  tags = {
    Name = "parking-management-vpc"
  }
}

resource "aws_subnet" "public_subnet_1a" {
  vpc_id = aws_vpc.main.id
  availability_zone = "ap-northeast-1a"
  cidr_block = "172.31.0.0/24"
  map_public_ip_on_launch = true # public subnetにはpublic IPを自動で割り当てる
  tags = {
    Name = "parking-management-public-subnet-1a"
  }
}

resource "aws_subnet" "public_subnet_1c" {
  vpc_id = aws_vpc.main.id
  availability_zone = "ap-northeast-1c"
  cidr_block = "172.31.1.0/24"
  map_public_ip_on_launch = true # public subnetにはpublic IPを自動で割り当てる
  tags = {
    Name = "parking-management-public-subnet-1c"
  }
}

resource "aws_subnet" "private_subnet_1a" {
  vpc_id = aws_vpc.main.id
  availability_zone = "ap-northeast-1a"
  cidr_block = "172.31.101.0/24"
  tags = {
    Name = "parking-management-private-subnet-1a"
  }
}

resource "aws_subnet" "private_subnet_1c" {
  vpc_id = aws_vpc.main.id
  availability_zone = "ap-northeast-1c"
  cidr_block = "172.31.102.0/24"
  tags = {
    Name = "parking-management-private-subnet-1c"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "parking-management-igw"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "parking-management-public-rt"
  }
}

# route tableに、「0.0.0.0/0なら、IGWにルーティングする」レコードを追加
resource "aws_route" "public_route" {
  route_table_id = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.main.id
}

# public-1aは、このpublic_route_tableに紐づく
resource "aws_route_table_association" "public_route_table_association_1a" {
  subnet_id = aws_subnet.public_subnet_1a.id
  route_table_id = aws_route_table.public_route_table.id
}

# public-1cは、このpublic_route_tableに紐づく
resource "aws_route_table_association" "public_route_table_association_1c" {
  subnet_id = aws_subnet.public_subnet_1c.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
  depends_on = [ aws_internet_gateway.main ]

  tags = {
    Name = "parking-management-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.public_subnet_1a.id # public subnetの1aに配置

  tags = {
    Name = "parking-management-nat-gateway"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "parking-management-private-rt"
  }
}

# route tableに、「0.0.0.0/0なら、NAT Gatewayにルーティングする」レコードを追加
resource "aws_route" "private_route" {
  route_table_id = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.main.id
}

# private-1aは、このprivate_route_tableに紐づく
resource "aws_route_table_association" "private_route_table_association_1a" {
  subnet_id = aws_subnet.private_subnet_1a.id
  route_table_id = aws_route_table.private_route_table.id
}

# private-1cは、このprivate_route_tableに紐づく
resource "aws_route_table_association" "private_route_table_association_1c" {
  subnet_id = aws_subnet.private_subnet_1c.id
  route_table_id = aws_route_table.private_route_table.id
}