provider "aws" {
  region     = var.region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

# Define SSH key resource, the public key is used here for SSH authorization
resource "aws_key_pair" "ubuntu_key" {
  key_name   = "terraform_key"
  public_key = file("/var/lib/jenkins/.ssh/id_rsa.pub")
}

# Define security group to allow SSH access
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

# Define the EC2 instance
resource "aws_instance" "ubuntu_instance" {
  ami             = var.ami_id  # Update this with the Ubuntu 22.04 AMI ID for your region
  instance_type   = "t3.medium"  # Instance type with 2 CPUs and 4 GB RAM
  key_name        = aws_key_pair.ubuntu_key.key_name
  security_groups = [aws_security_group.allow_ssh.name]

  tags = {
    Name = "TerraformUbuntu22"
  }

  # Connection details for remote-exec provisioner
  connection {
    type        = "ssh"
    user        = "admin"  # Ensure this is correct for Ubuntu AMI
    private_key = file("/var/lib/jenkins/.ssh/id_rsa")
    host        = self.public_ip
  }

  # Install Docker and Kubernetes using the remote-exec provisioner
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",

      # Install Docker
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sudo sh get-docker.sh",

      # Install dependencies for Minikube
      "sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl gnupg gnupg2 gnupg1 snapd",

      # Add Kubernetes apt repository
      "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
      "echo 'deb https://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee /etc/apt/sources.list.d/kubernetes.list",

      # Install kubectl
      "sudo snap install kubectl --classic",
      "kubectl version --client",

      # Install Minikube
      "curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64",
      "sudo install minikube-linux-amd64 /usr/local/bin/minikube",
      "minikube version",

      # Start Minikube with Docker driver
      "minikube start --driver=docker --force"
    ]
  }
}

# Output the public IP of the instance
output "instance_ip" {
  value = aws_instance.ubuntu_instance.public_ip
}
