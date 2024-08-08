# main.tf
provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_droplet" "web" {
  image  = "debian-11-x64"
  name   = "dust"
  region = "blr1"
  size   = "s-2vcpu-2gb"
  ssh_keys = []
  ipv6 = true

  tags = ["web"]

  connection {
    type     = "ssh"
    user     = "root"
    password = var.root_password
    host     = self.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "echo Hello, World!"
    ]
  }
}

/*variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "root_password" {
  description = "Root password for the droplet"
  type        = string
  sensitive   = true
}*/
