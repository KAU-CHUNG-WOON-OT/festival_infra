# ── VPC ───────────────────────────────────────────────────────
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "${var.name_prefix}-vpc" }
}

# ── Public Subnets ────────────────────────────────────────────
resource "aws_subnet" "public_2a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = { Name = "${var.name_prefix}-public-2a" }
}

resource "aws_subnet" "public_2c" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = { Name = "${var.name_prefix}-public-2c" }
}

# ── Private Subnets ───────────────────────────────────────────
resource "aws_subnet" "private_2a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "ap-northeast-2a"

  tags = { Name = "${var.name_prefix}-private-2a" }
}

resource "aws_subnet" "private_2c" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "ap-northeast-2c"

  tags = { Name = "${var.name_prefix}-private-2c" }
}

# ── Internet Gateway ──────────────────────────────────────────
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "${var.name_prefix}-igw" }
}

# ── NAT Gateway (단일, public-2a 배치) ───────────────────────
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = { Name = "${var.name_prefix}-nat-eip" }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_2a.id

  tags = { Name = "${var.name_prefix}-nat" }

  depends_on = [aws_internet_gateway.this]
}

# ── Route Tables ──────────────────────────────────────────────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = { Name = "${var.name_prefix}-public-rt" }
}

resource "aws_route_table_association" "public_2a" {
  subnet_id      = aws_subnet.public_2a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2c" {
  subnet_id      = aws_subnet.public_2c.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = { Name = "${var.name_prefix}-private-rt" }
}

resource "aws_route_table_association" "private_2a" {
  subnet_id      = aws_subnet.private_2a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2c" {
  subnet_id      = aws_subnet.private_2c.id
  route_table_id = aws_route_table.private.id
}

# ── Security Groups ───────────────────────────────────────────

# sg_alb: 인터넷 → 80, 443
resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-sg-alb"
  description = "ALB: inbound 80/443 from internet"
  vpc_id      = aws_vpc.this.id

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

  tags = { Name = "${var.name_prefix}-sg-alb" }
}

# sg_main: ALB SG → 8080 (메인 서비스)
resource "aws_security_group" "main" {
  name        = "${var.name_prefix}-sg-main"
  description = "Main service: inbound 8080 from ALB"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "From ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-sg-main" }
}

# sg_vote: ALB SG → 8081 (투표 서비스)
resource "aws_security_group" "vote" {
  name        = "${var.name_prefix}-sg-vote"
  description = "Vote service: inbound 8081 from ALB"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "From ALB"
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-sg-vote" }
}

# sg_bastion: SSH 접속 전용 (키페어 인증)
resource "aws_security_group" "bastion" {
  name        = "${var.name_prefix}-sg-bastion"
  description = "Bastion: inbound SSH from anywhere (key-pair auth)"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-sg-bastion" }
}

# sg_db: Main + Vote SG → 3306 (MySQL/Aurora)
resource "aws_security_group" "db" {
  name        = "${var.name_prefix}-sg-db"
  description = "DB: inbound 3306 from main and vote services"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "From Main service"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.main.id]
  }

  ingress {
    description     = "From Vote service"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.vote.id]
  }

  ingress {
    description     = "From Bastion"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  tags = { Name = "${var.name_prefix}-sg-db" }
}

# sg_cache: Main + Vote SG → 6379 (Redis)
resource "aws_security_group" "cache" {
  name        = "${var.name_prefix}-sg-cache"
  description = "Cache: inbound 6379 from main and vote services"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "From Main service"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.main.id]
  }

  ingress {
    description     = "From Vote service"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.vote.id]
  }

  tags = { Name = "${var.name_prefix}-sg-cache" }
}
