output "created_vpc" {
  description = "VPC id created :"
  value       = aws_vpc.vpc_joaquim.id
}

output "subnet_private" {
  description = "Id for private subnet"
  value       = aws_subnet.private_subnet-joaquim.id
}

output "subnet_public" {
  description = "ID for public subnet"
  value       = aws_subnet.public_subnet-joaquim.id
}

output "front_ip" {
  description = "Public IP addresses of the EC2 instances"
  value       = aws_instance.testing-front-joaquim.public_ip
}


output "bastion_ip" {
  description = "Public IP addresses of the EC2 instances"
  value       = aws_instance.bastion.public_ip
}

## these 2 dont have a public ip because they are on a private subnet 

output "app_ip" {
  description = "Public IP addresses of the EC2 instances"
  value       = aws_instance.testing-bck-joaquim-app.private_ip
}


output "db_ip" {
  description = "Public IP addresses of the EC2 instances"
  value       = aws_instance.testing-bck-joaquim-db.private_ip
}


