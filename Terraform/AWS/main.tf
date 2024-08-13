provider "aws" {
  region     = var.region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

# Define SSH key resource, the public key is used here for ssh authorization, you can use ssh-keygen command to generate a key pair on your linux machine
resource "aws_key_pair" "debian_key" {
  key_name   = "terraform_key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Define security group, it will allow port 22 for ssh connections
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define ec2 instance
resource "aws_instance" "debian_instance" {
  ami             = var.ami_id
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.debian_key.key_name
  security_groups = [aws_security_group.allow_ssh.name]

  tags = {
    Name = "TerraformDebian12"
  }

  connection {
    type        = "ssh"
    user        = "admin"  # Ensure this is correct
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 10",
      "echo Hello, World!",
    ]
  }
}

# the public IP of the ec2 instance will be displayed on the terminal
output "instance_ip" {
  value = aws_instance.debian_instance.public_ip
}
