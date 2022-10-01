# Configure the Microsoft Azure Provider.
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  } 

  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {
  }
}

# Create azure resource group
resource "azurerm_resource_group" "rg_nameless" {
  name     = var.resource_group_name
  location = var.location
}

# Create virtual network for the VM
resource "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  location            = var.location
  address_space       = var.address_space
  resource_group_name = azurerm_resource_group.rg_nameless.name
}

# Create subnet to the virtual network
resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}_subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg_nameless.name
  address_prefixes     = var.subnet_prefix
}

# Create public ip
resource "azurerm_public_ip" "pip_terraform" {
  name                = "${var.prefix}-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_nameless.name
  allocation_method   = "Dynamic"
  domain_name_label   = var.hostname
}

# Create Network security group
resource "azurerm_network_security_group" "terraform_sg" {
  name                = "${var.prefix}-sg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_nameless.name

  security_rule {
    name                       = "HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create Network interface
resource "azurerm_network_interface" "terraform_nic" {
  name                = "${var.prefix}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_nameless.name

  ip_configuration {
    name                          = "${var.prefix}-ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_terraform.id
  }
}

# Create Linux VM
resource "azurerm_linux_virtual_machine" "vm_terraform" {
  name                = "${var.hostname}-vm"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_nameless.name
  size                = var.vm_size
  disk_size_gb =  var.os_disk_linux
  custom_data = filebase64("customdata.sh")

  network_interface_ids         = ["${azurerm_network_interface.terraform_nic.id}"]

  computer_name  = var.hostname
  admin_username = var.admin_username
  admin_password = var.admin_password 
  disable_password_authentication = false

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  os_disk  {
    name              = "${var.hostname}_osdisk"
    storage_account_type  = "Standard_LRS"
    caching           = "ReadWrite"
  }

}


/*Windows*/

storage Image_reference {
publisher="MicrosoftWindowsServer"
offer="WindowsServer"
sku="2019-Datacenter"
version="latest"
}
storage_os_disck{
  name              = "${var.prefix}-OS_disk01"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
}
os_profile {
  computer_name = "PIP-SRV-PROD-01-AZ"
  admin_username = "admin"
  admin_password = "p4ssword"  
}

os_profile_windows_config {
  #disable_password_authentication = false
  #ssh_keys{
  # key_data = file("mykey.pub")
  # path = "/home/linuxusr/.shh/authorized_keys"
  #}
  }

resource "azurerm_network_security_group" "allow-ssh" {
  name= "RG-PROD-01"
  location = "East US"
  resource_group_name = azurerm_resource_group.test02.name

  security_rule {
   
    access = ""
    protocol = ""
    source_port_range=""
    destination_address_prefix =""
    destinationsource_address_prefix = "*" 
    name                       = "HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_ranges =  "*"
    destination_port_range = "3389"
    source_address_prefix = var.ssh_source_address
    destination_address_prefixes =  "*"
  }
  
  
}
