output "vpc_id" {
  value       = aws_vpc.main.id
  description = "ID of the VPC created for Lab 1"
}

output "vpc_cidr" {
  value       = aws_vpc.main.cidr_block
  description = "CIDR block of the Lab 1 VPC"
}
