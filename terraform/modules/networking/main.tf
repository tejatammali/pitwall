# ─── VPC ────────────────────────────────────────────────────────────────────
# The VPC is your private network in AWS. Nothing inside can talk to the
# internet unless you explicitly allow it. Think of it as the walls of
# your office building.

resource "aws_vpc" "pitwall" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# ─── INTERNET GATEWAY ───────────────────────────────────────────────────────
# The internet gateway is the front door of your VPC. Without it, nothing
# inside the VPC can reach the internet and nothing from the internet
# can reach inside. Public subnets use this directly.

resource "aws_internet_gateway" "pitwall" {
  vpc_id = aws_vpc.pitwall.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# ─── PUBLIC SUBNETS ─────────────────────────────────────────────────────────
# Public subnets are directly reachable from the internet.
# Your load balancer lives here — it receives traffic and forwards it
# to your private EKS nodes.
# count = 2 means Terraform creates this resource twice, once per AZ.

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.pitwall.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${var.project_name}-${var.environment}-public-${var.availability_zones[count.index]}"
    "kubernetes.io/role/elb" = "1"
  }
}

# ─── PRIVATE SUBNETS ────────────────────────────────────────────────────────
# Private subnets have no direct route to the internet.
# Your EKS worker nodes (the machines running your robot pods) live here.
# They can still reach the internet outbound via the NAT gateway —
# for example to pull Docker images — but nothing can reach them directly.

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.pitwall.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                              = "${var.project_name}-${var.environment}-private-${var.availability_zones[count.index]}"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# ─── ELASTIC IP FOR NAT GATEWAY ─────────────────────────────────────────────
# The NAT gateway needs a fixed public IP address.
# This reserves one for it.

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-eip"
  }

  depends_on = [aws_internet_gateway.pitwall]
}

# ─── NAT GATEWAY ────────────────────────────────────────────────────────────
# The NAT gateway sits in the public subnet and acts as a middleman.
# Private subnet resources (your EKS nodes) send outbound traffic to
# the NAT gateway, which forwards it to the internet using its public IP.
# Inbound traffic from the internet cannot initiate a connection back in.
# Think of it like a one-way mirror — you can see out, nobody can see in.

resource "aws_nat_gateway" "pitwall" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project_name}-${var.environment}-nat"
  }

  depends_on = [aws_internet_gateway.pitwall]
}

# ─── PUBLIC ROUTE TABLE ─────────────────────────────────────────────────────
# A route table is like a GPS for network traffic — it tells packets
# where to go. The public route table says: for any traffic going to
# the internet (0.0.0.0/0), send it through the internet gateway.

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.pitwall.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.pitwall.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

# ─── PRIVATE ROUTE TABLE ────────────────────────────────────────────────────
# The private route table says: for outbound internet traffic,
# send it through the NAT gateway instead of directly out.

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.pitwall.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.pitwall.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt"
  }
}

# ─── ROUTE TABLE ASSOCIATIONS ───────────────────────────────────────────────
# Associating a subnet with a route table activates those routing rules
# for that subnet. Without this, subnets don't know which route table
# to follow.

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}