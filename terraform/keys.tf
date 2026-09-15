# Generates private RSA keys for each host
resource "tls_private_key" "frontend" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "backend" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "database" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Regista as chaves públicas na AWS
resource "aws_key_pair" "frontend" {
  key_name   = "joaquim-frontend-key"
  public_key = tls_private_key.frontend.public_key_openssh
}

resource "aws_key_pair" "backend" {
  key_name   = "joaquim-backend-key"
  public_key = tls_private_key.backend.public_key_openssh
}

resource "aws_key_pair" "database" {
  key_name   = "joaquim-database-key"
  public_key = tls_private_key.database.public_key_openssh
}

# Saves private keys locally (to owner only)
resource "local_sensitive_file" "frontend_key" {
  content         = tls_private_key.frontend.private_key_pem
  filename        = "Project1_singleAZ/../keys/frontend.pem"
  file_permission = "0600"
}

resource "local_sensitive_file" "backend_key" {
  content         = tls_private_key.backend.private_key_pem
  filename        = "Project1_singleAZ/../keys/backend.pem"
  file_permission = "0600"
}

resource "local_sensitive_file" "database_key" {
  content         = tls_private_key.database.private_key_pem
  filename        = "Project1_singleAZ/../keys/database.pem"
  file_permission = "0600"
}