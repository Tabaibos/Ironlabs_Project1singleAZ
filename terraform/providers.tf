terraform {
  backend "s3" {
    bucket         = "tfstate-joaquim-p1"         # Replace with your actual S3 bucket name
    key            = "terraform.tfstate"          # The file path to store the state
    region         = "us-east-1"                  # Your AWS region
    encrypt        = true                         # Encrypt state file at rest
    dynamodb_table = "DynamoDB-Terraform-joaquim" # DynamoDB table for state locking
  }
}
