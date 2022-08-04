output "private_subnet_ids" {
    description = "VPC's private subnets"
    value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
    description = "VPC's private subnets"
    value       = aws_subnet.public[*].id
}

output "db_subnet_ids" {
    description = "VPC's db subnets"
    value       = aws_subnet.db[*].id
}

output "vpc_id" {
    description = "AWS VPC ID"
    value = aws_vpc.vpc.id
}