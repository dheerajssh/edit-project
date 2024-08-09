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

# Define SSH key resource
resource "digitalocean_ssh_key" "default" {
  name       = "my-ssh-key"
  public_key = file("~/.ssh/id_rsa.pub")  # Path to your public key file
}

# Define your droplet resource
resource "digitalocean_droplet" "web" {
  image  = "debian-11-x64"
  name   = "dust"
  region = "blr1"
  size   = "s-2vcpu-2gb"
  ssh_keys = [digitalocean_ssh_key.default.id]
  ipv6 = true

  tags = ["web"]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file("~/.ssh/id_rsa")
    host        = self.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "echo Hello, World!"
    ]
  }
}