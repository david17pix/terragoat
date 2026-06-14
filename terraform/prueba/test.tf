terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

provider "azurerm" {
  features {}
}


# -------------------------
# VARIABLES
# -------------------------
variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

# -------------------------
# PASSWORD GENERATOR
# -------------------------
resource "random_string" "password" {
  length      = 16
  special     = false
  min_lower   = 1
  min_numeric = 1
  min_upper   = 1
}

# -------------------------
# RESOURCE GROUP
# -------------------------
resource "azurerm_resource_group" "example" {
  name     = "terragoat-rg"
  location = var.location
}

# -------------------------
# VIRTUAL NETWORK
# -------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = "terragoat-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]
}

# -------------------------
# SUBNET
# -------------------------
resource "azurerm_subnet" "subnet" {
  name                 = "terragoat-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# -------------------------
# NETWORK INTERFACES
# -------------------------
resource "azurerm_network_interface" "ni_linux" {
  name                = "ni-linux"
  location            = var.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "ni_win" {
  name                = "ni-win"
  location            = var.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# -------------------------
# LINUX VM
# -------------------------
resource "azurerm_linux_virtual_machine" "linux_machine" {
  name                = "terragoat-linux"
  location            = var.location
  resource_group_name = azurerm_resource_group.example.name
  size                = "Standard_F2"

  admin_username                  = "terragoat-linux"
  admin_password                  = random_string.password.result
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.ni_linux.id
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

# -------------------------
# WINDOWS VM
# -------------------------
resource "azurerm_windows_virtual_machine" "windows_machine" {
  name                = "terragoat-windows"
  location            = var.location
  resource_group_name = azurerm_resource_group.example.name
  size                = "Standard_F2"

  admin_username = "tg-admin"
  admin_password = random_string.password.result

  network_interface_ids = [
    azurerm_network_interface.ni_win.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}
