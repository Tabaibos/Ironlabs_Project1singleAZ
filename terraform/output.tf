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
  value       = aws_instance.frontend-joaquim.public_ip
}


output "bastion_ip" {
  description = "Public IP addresses of the EC2 instances"
  value       = aws_instance.bastion.public_ip
}

## privat ips to send to bastion for host file configuration

output "app_ip" {
  description = "Public IP addresses of the EC2 instances"
  value       = aws_instance.back-joaquim.private_ip
}


output "db_ip" {
  description = "Public IP addresses of the EC2 instances"
  value       = aws_instance.Posgres-joaquim.private_ip
}

output "front_ip_priv" {
  description = "Public IP addresses of the EC2 instances"
  value       = aws_instance.frontend-joaquim.private_ip
}

output "front_ip_pub" {
  description = "Public IP addresses of the EC2 instances"
  value       = aws_instance.frontend-joaquim.public_ip
}

output "key_path" {
  value = "~/${var.key_name}.pem"
}

#output "frontend_key_path" {
#  value = local_sensitive_file.frontend_key.filename
#}

#output "backend_key_path" {
#  value = local_sensitive_file.backend_key.filename
#}

#output "database_key_path" {
#  value = local_sensitive_file.database_key.filename
#}