
resource "azurerm_resource_group" "resource_group" {
  location = var.resource_location
  name     = var.resource_group_name

}

resource "azurerm_virtual_network" "vnet" {
  address_space       = ["10.0.0.0/16"]
  location            = var.resource_location
  name                = "myVnet"
  resource_group_name = azurerm_resource_group.resource_group.name
}


resource "azurerm_subnet" "subnet" {
  address_prefixes     = ["10.0.0.0/24"]
  name                 = "mysubnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_public_ip" "ip" {
  allocation_method   = "Static"
  location            = var.resource_location
  name                = "myip"
  resource_group_name = azurerm_resource_group.resource_group.name
  sku = "Standard"
}

resource "azurerm_network_interface" "interface" {
  location            = var.resource_location
  name                = "myInterface"
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "my_nic_configuration"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.ip.id
    subnet_id = azurerm_subnet.subnet.id
  }
}

resource "azurerm_network_security_group" "nsg" {
  location            = var.resource_location
  name                = "mynsg"
  resource_group_name = azurerm_resource_group.resource_group.name

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
  security_rule {
    name                       = "HTTP"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"


  }

}

resource "azurerm_network_interface_security_group_association" "association" {
  network_interface_id      = azurerm_network_interface.interface.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_storage_account" "storage_account" {
  account_replication_type = "LRS"
  account_tier             = "Standard"
  location                 = var.resource_location
  name                     = "account5432"
  resource_group_name      = azurerm_resource_group.resource_group.name
}

resource "azurerm_linux_virtual_machine" "linux_vm" {
  admin_username        = "admin_user"
  location              = var.resource_location
  name                  = "myVm"
  network_interface_ids = [azurerm_network_interface.interface.id]
  resource_group_name   = azurerm_resource_group.resource_group.name
  size                  = "Standard_B2s"


  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  admin_ssh_key {
    public_key = file("~/.ssh/id_rsa.pub")
    username   = "admin_user"
  }
  custom_data = base64encode(file("script.sh"))
}

output "azure_public_ip" {
  value = azurerm_public_ip.ip.ip_address
}

output "azure_vm_name" {
  value = azurerm_linux_virtual_machine.linux_vm.admin_username
}



