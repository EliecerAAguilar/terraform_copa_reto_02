# # Configure the Microsoft Azure Provider.
# terraform {
#   required_providers {
#     azurerm = {
#       source  = "hashicorp/azurerm"
#       version = ">= 2.26"
#     }
#   } 


# }

# provider "azurerm" {
#   features {
#   }
# }

resource "azurerm_vitual_machine" "Test01-instance" {
    name = "${var.prefix}-vm01"
    location = var.location
    resource_group_name = azurerm_resource_group_Test01.name
    network_interface_ids = [azurerm_network_interface.Test01-instance.id]
    vm_size = "Standard_B2s"

    delete_os_disk_termination = true
    delete_data_disks_on_termination = true
    
    storage_image_reference {
        publisher="MicrosoftWindowsServer"
        offer="WindowsServer"
        sku="2019-Datacenter"
        version="latest"
    }
    storage_os_disck{
        name="${var.prefix}-OSdisk01"
        caching="ReadWrite"
        create_option="FromImage"
        managed_disk_type="Standard_LRS"
    }
    os_profile{
        computer_name="PIP-SRV-PROD-01-AZ"
        admin_username="wnuadmin"
        admin_password="N4m3l3ss"
    }
    os_profile_windows_config{
        #disble_password_authentication=false
        #ssh_keys{
        #key_data=file(""mykey.pub)
        #path = "/home/linuxsr/.ssh/authorized_keys"
        #}
        }

}   

resource "azurerm_virtual_network" "Test01" {    
    name = "${var.prefix}-network"
    location = var.location
    resource_group_name = azurerm_resource_group.Test01.name
    address_space = var.address_space
    
}
resource "azurem_subnet" "Test01-internal-1" {
 name= "${var.prefix}-internal-1"
 resource_group_name= azurerm_resource_group_Test01.name
 virtual_network_name= azurerm_virtual_network_Test01.name
 address_prefix=var.subnet_prefix
}
resource "azurerm_network_security_group" "allow-ssh"{
    name="${var.prefix}-allow-ssh"
    location= var.location
    resource_group_name= azurerm_resource_group.Test01.name
    security_rule {
        name="SSH"
        priority= 310
        direction="Inbound"
        access="Allow"
        protocool="Tcp"
        source_port_range ="*"
        desitnation_port_range="22"
        source_address_prefix= var.ssh-source-address
        destination_address_prefix="*"
        
    }
}
