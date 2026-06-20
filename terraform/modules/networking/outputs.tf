output "vpc_id" {
  description = "ID of the Pitwall VPC"
  value       = aws_vpc.pitwall.id
}

output "vpc_cidr" {
  description = "CIDR block of the Pitwall VPC"
  value       = aws_vpc.pitwall.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets — load balancer lives here"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets — EKS nodes live here"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_id" {
  description = "ID of the NAT gateway"
  value       = aws_nat_gateway.pitwall.id
}