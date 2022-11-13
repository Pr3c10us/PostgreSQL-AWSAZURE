# Create a resource group
resource "azurerm_resource_group" "rg" {
  name      = var.resource_group_name
  location  = var.azure_location
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
  name                = "NetworkSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
  name                = "AZ_NIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.myterraformsubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.myterraformnic.id
  network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "myterraformvm" {
  name                            = "azure-pg"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  network_interface_ids           = [azurerm_network_interface.myterraformnic.id]
  size                            = "Standard_D2ads_v5"
  admin_username                  = "azureuser"
  admin_password                  = "P@ssw0rd1234!"
  disable_password_authentication = false

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  # connection {
  #   type        = "ssh"
  #   host     = self.public_ip_address
  #   user     = self.admin_username
  #   private_key = tls_private_key.example_ssh.private_key_pem
  # }
  # provisioner "file" {
  #   source      = "./script-init.sh"
  #   destination = "/tmp/script-init.sh"

  # }

  # provisioner "remote-exec" {
  #   inline = [
  #     "echo done",
  # "tr -d '\r' </tmp/script-init.sh >a.tmp",
  # "mv a.tmp script-init.sh",
  # "chmod +x ./script-init.sh",
  # "sudo ./script-init.sh",
  #   ]
  # }
  # provisioner "remote-exec" {
  #   inline = [
  #     "echo ${azurerm_linux_virtual_machine.myterraformvm.public_ip_address}",
  #     "#sudo -i -u postgres sshpass -p 'postgres' ssh-copy-id postgres@${azurerm_linux_virtual_machine.myterraformvm.public_ip_address}",
  #   ]
  # }
}

