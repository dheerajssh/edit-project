provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

# Define Resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = "Central India"
}

# Define Virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "myVNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Define Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Define Network Interface
resource "azurerm_network_interface" "nic" {
  name                = "myNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Define Public IP
resource "azurerm_public_ip" "public_ip" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Define Virtual machine
resource "azurerm_linux_virtual_machine" "my_vm" {
  name                = "myVM"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D2ls_v5"

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_username = "adminuser"

  # Define SSH key resource, the public key is used here for ssh authorization
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("/var/lib/jenkins/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-jammy"
  sku       = "22_04-lts-gen2"
  version   = "latest"
  }

  depends_on = [azurerm_public_ip.public_ip]
}

# Wait for Public IP to be allocated
resource "null_resource" "wait_for_ip" {
  provisioner "local-exec" {
    command = "sleep 60"
  }

  depends_on = [azurerm_linux_virtual_machine.my_vm]
}

# Fetch Public IP after allocation
data "azurerm_public_ip" "my_public_ip" {
  name                = azurerm_public_ip.public_ip.name
  resource_group_name = azurerm_resource_group.rg.name
  depends_on          = [null_resource.wait_for_ip]
}

# Install Docker and Minikube on the VM
resource "null_resource" "install_docker_minikube" {
  provisioner "remote-exec" {
    inline = [

      # Update package list
      "sudo apt-get update",

      # Install Docker
      "echo 'Installing Docker...'",
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sudo sh get-docker.sh",

      # Add user to Docker group
      "echo 'Adding user to Docker group...'",
      "sudo usermod -aG docker adminuser",

      # Install dependencies for Minikube
      "echo 'Installing dependencies for Minikube...'",
      "sudo apt-get install -y apt-transport-https ca-certificates curl gnupg gnupg2 gnupg1 snapd",

      # Add Kubernetes apt repository
      "echo 'Adding Kubernetes apt repository...'",
      "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
      "echo 'deb https://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee /etc/apt/sources.list.d/kubernetes.list",

      # Install kubectl
      "echo 'Installing kubectl...'",
      "sudo snap install kubectl --classic",
      "kubectl version --client",

      # Install Minikube
      "echo 'Installing Minikube...'",
      "sudo curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64",
      "sudo install minikube-linux-amd64 /usr/local/bin/minikube",
      "minikube version",

      # Start Minikube with Docker driver
      "echo 'Starting Minikube...'",
      "sudo minikube start --driver=docker --force",
#      "sudo minikube status"
    ]

    connection {
      type        = "ssh"
      host        = data.azurerm_public_ip.my_public_ip.ip_address
      user        = "adminuser"
      private_key = file("/var/lib/jenkins/.ssh/id_rsa")
    }
  }
  depends_on = [data.azurerm_public_ip.my_public_ip]
}

output "admin_username" {
  value = azurerm_linux_virtual_machine.my_vm.admin_username
}

output "virtual_machine_ip_address" {
  value = data.azurerm_public_ip.my_public_ip.ip_address
}
