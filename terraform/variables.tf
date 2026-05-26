variable "region" {
  description = "The AWS region to deploy in."
  default     = "us-east-1"
}

variable "availability_zone" {
  description = "Az zone"
  default     = "us-east-1a"

}

variable "myIP" {
  description = "my ip for sh connection"
  type        = string
}


variable "ami-image" {
  type    = string
  default = "ami-091138d0f0d41ff90"
}

variable "instance_type" {
  description = "EC2 instance type."
  default     = "t3.micro"
}

variable "key_name" {
  description = "key for ssh connection"
  type        = string
}
