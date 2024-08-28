terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

# Define SSH key resource, the public key is used here for ssh authorization
resource "digitalocean_ssh_key" "default" {
  name       = "my-ssh-key"
  public_key = file("/var/lib/jenkins/.ssh/id_rsa.pub")
}

# Define droplet resources
resource "digitalocean_droplet" "web" {
  image  = "ubuntu-22-04-x64"
  name   = "dust"
  region = "blr1"
  size   = "s-2vcpu-4gb"
  ssh_keys = [digitalocean_ssh_key.default.id]
  ipv6 = true

  tags = ["web"]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file("/var/lib/jenkins/.ssh/id_rsa")
    host        = self.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",

      # Install Docker
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sudo sh get-docker.sh",

      # Install minikube
      # Install dependencies
      "sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl",

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
      "minikube start --driver=docker --force",
    ]
  }
}

output "droplet_ip" {
  value = digitalocean_droplet.web.ipv4_address
}
