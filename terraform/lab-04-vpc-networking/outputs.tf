output "vpc_id" {
  value       = aws_vpc.net.id
  description = "VPC ID"
}

output "vpc_cidr" {
  value       = aws_vpc.net.cidr_block
  description = "VPC CIDR block"
}

output "public_subnet_id" {
  value       = aws_subnet.public.id
  description = "Public subnet ID (10.30.1.0/24, ap-south-1a)"
}

output "private_subnet_id" {
  value       = aws_subnet.private.id
  description = "Private subnet ID (10.30.2.0/24, ap-south-1b)"
}

output "internet_gateway_id" {
  value       = aws_internet_gateway.igw.id
  description = "Internet Gateway ID"
}

output "public_route_table_id" {
  value       = aws_route_table.public.id
  description = "Public route table ID"
}

output "web_security_group_id" {
  value       = aws_security_group.web.id
  description = "Web tier security group ID"
}

output "db_security_group_id" {
  value       = aws_security_group.db.id
  description = "Database tier security group ID"
}
