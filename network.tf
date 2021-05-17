resource "aws_vpc" "pro_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "production vpc"
  }
}

resource "aws_subnet" "public_sn" {
  vpc_id     = aws_vpc.pro_vpc.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "public subnet"
  }
}

resource "aws_subnet" "private_sn_1" {
  vpc_id            = aws_vpc.pro_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "private subnet 1"
  }
}

resource "aws_subnet" "private_sn_2" {
  vpc_id            = aws_vpc.pro_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "private subnet 2"
  }
}


resource "aws_nat_gateway" "nat_gw" {
  subnet_id = aws_subnet.public_sn.id

  tags = {
    Name = "Nat gateway"
  }
}

resource "aws_db_subnet_group" "db_sn_group" {
  name       = "db subnet group"
  subnet_ids = [aws_subnet.private_sn_1.id, aws_subnet.private_sn_2.id]
  tags = {
    Name = "Database subnet group"
  }
}

resource "aws_elasticache_subnet_group" "elasticache_sg" {
  name       = "elasticache subnet group"
  subnet_ids = [aws_subnet.private_sn_1.id, aws_subnet.private_sn_2.id]
}

resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.pro_vpc.id

  tags = {
    Name = "Internet gateway"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.pro_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gw.id
  }

  tags = {
    Name = "Route table for vpc"
  }
}

# Associate subnet with route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.private_sn_1.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.private_sn_2.id
  route_table_id = aws_route_table.route_table.id
}

# create security group
resource "aws_security_group" "redis_sg" {
  name        = "Redis security group"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.pro_vpc.id

  ingress {
    description      = "Custom TCP"
    from_port        = 6379
    to_port          = 6379
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Redis security group"
  }
}

resource "aws_security_group" "postgres_sg" {
  name        = "Postgres security group"
  description = "Postgres security group"
  vpc_id      = aws_vpc.pro_vpc.id

  ingress {
    description      = "PostgreSQL"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Database security group"
  }
}