# Depends on: variables.tf (var.vpc_cidr, var.cluster_name, var.allowed_ssh_cidr)
# Feeds: ec2.tf (aws_subnet.cluster, aws_security_group.cluster)
#
# aws_vpc.cluster ─→ aws_internet_gateway.cluster ─→ aws_route_table.cluster ─→ aws_route_table_association.cluster
#                 ├─→ aws_subnet.cluster
#                 └─→ aws_security_group.cluster
# data.aws_availability_zones.available ─→ aws_subnet.cluster

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "cluster" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

resource "aws_internet_gateway" "cluster" {
  vpc_id = aws_vpc.cluster.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

resource "aws_subnet" "cluster" {
  vpc_id                  = aws_vpc.cluster.id
  cidr_block              = var.vpc_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.cluster_name}-subnet"
  }
}

resource "aws_route_table" "cluster" {
  vpc_id = aws_vpc.cluster.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cluster.id
  }

  tags = {
    Name = "${var.cluster_name}-rt"
  }
}

resource "aws_route_table_association" "cluster" {
  subnet_id      = aws_subnet.cluster.id
  route_table_id = aws_route_table.cluster.id
}

resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-sg"
  description = "Patroni/etcd cluster: node-to-node and admin access"
  vpc_id      = aws_vpc.cluster.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # PostgreSQL direct + pgbouncer
  ingress {
    description = "Postgres and pgbouncer, within the cluster subnet"
    from_port   = 5432
    to_port     = 6432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # etcd client + peer
  ingress {
    description = "etcd client and peer traffic"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Patroni REST API
  ingress {
    description = "Patroni REST API"
    from_port   = 8008
    to_port     = 8008
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # HAProxy stats
  ingress {
    description = "HAProxy stats UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-sg"
  }
}
