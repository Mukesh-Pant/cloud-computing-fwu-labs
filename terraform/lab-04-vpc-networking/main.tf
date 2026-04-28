resource "aws_vpc" "net" {
  cidr_block           = "10.30.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc-${var.suffix}-net"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.net.id

  tags = {
    Name = "igw-${var.suffix}"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.net.id
  cidr_block              = "10.30.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-${var.suffix}-public"
    Tier = "public"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.net.id
  cidr_block        = "10.30.2.0/24"
  availability_zone = "${var.region}b"

  tags = {
    Name = "subnet-${var.suffix}-private"
    Tier = "private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.net.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "rt-${var.suffix}-public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.net.id

  tags = {
    Name = "rt-${var.suffix}-private"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "web" {
  name        = "${var.suffix}-web-sg"
  description = "Allow HTTP and HTTPS from anywhere (web tier)"
  vpc_id      = aws_vpc.net.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
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
    Name = "${var.suffix}-web-sg"
  }
}

resource "aws_security_group" "db" {
  name        = "${var.suffix}-db-sg"
  description = "Allow MySQL from web tier only (database tier)"
  vpc_id      = aws_vpc.net.id

  ingress {
    description     = "MySQL from web tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.suffix}-db-sg"
  }
}
