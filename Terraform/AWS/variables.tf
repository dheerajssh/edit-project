# The default region here is Mumbai
# The default ami_id is of a debian 12 machine in Mumbai region
# you can change these values and set to default here
variable "region" {
  description = "The AWS region to create resources in"
  default     = "ap-south-1"
}

variable "ami_id" {
  description = "The AMI ID to use for the EC2 instance"
  default     = "ami-061e327e2d858410e"
}

variable "aws_access_key_id" {
  description = "The AWS access key ID"
  type        = string
}

variable "aws_secret_access_key" {
  description = "The AWS secret access key"
  type        = string
}
