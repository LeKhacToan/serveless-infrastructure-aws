resource "aws_vpc" "pro_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name} production vpc"
  }
}

resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.pro_vpc.id

  tags = {
    Name = "${var.project_name} internet gateway"
  }
}

resource "aws_subnet" "public_sn" {
  vpc_id     = aws_vpc.pro_vpc.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "${var.project_name} public subnet"
  }
}

resource "aws_subnet" "private_sn_1" {
  vpc_id            = aws_vpc.pro_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.availability_zone_names[0]}"

  tags = {
    Name = "${var.project_name} private subnet 1"
  }
}

resource "aws_subnet" "private_sn_2" {
  vpc_id            = aws_vpc.pro_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.availability_zone_names[1]}"

  tags = {
    Name = "${var.project_name} private subnet 2"
  }
}

resource "aws_eip" "nat" {
  depends_on = [aws_internet_gateway.internet_gw]
}

resource "aws_nat_gateway" "nat_gw" {
  subnet_id = aws_subnet.public_sn.id
  allocation_id = aws_eip.nat.id
  tags = {
    Name = "${var.project_name} nat gateway"
  }
}

resource "aws_db_subnet_group" "db_sn_group" {
  name       = "db subnet group"
  subnet_ids = [aws_subnet.private_sn_1.id, aws_subnet.private_sn_2.id, aws_subnet.public_sn.id]
  tags = {
    Name = "${var.project_name} database subnet group"
  }
}

resource "aws_elasticache_subnet_group" "redis_sg" {
  name       = "elasticache-sg"
  subnet_ids = [aws_subnet.private_sn_1.id, aws_subnet.private_sn_2.id]
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.pro_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "${var.project_name} private route table for vpc"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.pro_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gw.id
  }

  tags = {
    Name = "${var.project_name} public route table for vpc"
  }
}

# Associate subnet with route table
resource "aws_route_table_association" "association_private_1" {
  subnet_id      = aws_subnet.private_sn_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "association_private_2" {
  subnet_id      = aws_subnet.private_sn_2.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "association_public" {
  subnet_id      = aws_subnet.public_sn.id
  route_table_id = aws_route_table.public_route_table.id
}

# Security group
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
    Name = "${var.project_name} redis security group"
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
    Name = "${var.project_name} database security group"
  }
}

resource "aws_security_group" "lambda_sg" {
  name        = "Lambda security group"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.pro_vpc.id

  ingress {
    description      = "All"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
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
    Name = "${var.project_name} lambda security group"
  }
}