
#####   REGION ###################
provider "aws" {
  region = var.region
}

############## S3 ###########################
resource "aws_s3_bucket" "joaquimp1" {
  bucket = "tfstate-joaquim-p1"

  tags = {
    Name = "Testing Joaquim"
  }
}



resource "aws_dynamodb_table" "terraform-P1-joaquim" {
  name           = "DynamoDB-Terraform-joaquim"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "dynamodb-table"
    Environment = "DEV"
  }
}