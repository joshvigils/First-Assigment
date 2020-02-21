resource "azurerm_resource_group" "Monitoring" {
    name = "Monitoring"
    location = var.loc
	tags = var.tags
}

resource "azurerm_virtual_network" "Monitoring-Vnet" {
    name = "Monitoring-Vnet"
    address_space = ["192.168.100.0/24"]
    location = azurerm_resource_group.Monitoring.location
    resource_group_name = azurerm_resource_group.Monitoring.name
}
resource "azurerm_subnet" "DMZ" {
    name    = "DMZ"
    resource_group_name = azurerm_resource_group.Monitoring.name
    virtual_network_name = azurerm_virtual_network.Monitoring-Vnet.name
    address_prefix = "192.168.100.0/27"
}
resource "azurerm_public_ip" "VM01-PIP" {
    name = "VM01-PIP"
    location = azurerm_resource_group.Monitoring.location
    resource_group_name = azurerm_resource_group.Monitoring.name
    allocation_method = "dynamic"
}

resource "azurerm_network_security_group" "VMNSG" {
    name = "VMNSG"
    location = azurerm_resource_group.Monitoring.location
    resource_group_name = azurerm_resource_group.Monitoring.name

    security_rule {
        name = "Remote-Access"
        priority = 100
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "22"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }
    tags = azurerm_resource_group.Monitoring.tags
}


resource "azurerm_network_interface" "VMnic" {
    name = "VMnic"
    location = azurerm_resource_group.Monitoring.location
    resource_group_name = azurerm_resource_group.Monitoring.name
    network_security_group_id = azurerm_network_security_group.VMNSG.id 

ip_configuration {
    name = "vNic-Configuration"
    subnet_id = azurerm_subnet.DMZ.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id = azurerm_public_ip.VM01-PIP.id 
 }
}
resource "azurerm_virtual_machine" "VM01" {
    name = "VM01"
    location = azurerm_resource_group.Monitoring.location
    resource_group_name = azurerm_resource_group.Monitoring.name
    network_interface_ids = [azurerm_network_interface.VMnic.id]
    vm_size = "Standard_D2s_v3"

    storage_image_reference {
        
        publisher = "Canonical"
        offer = "UbuntuServer"
        sku = "18.04-LTS"
        version = "Latest"
    }
    storage_os_disk {
        name = "OSdisk"
        caching = "none"
        create_option = "FromImage" 
        managed_disk_type = "Standard_LRS"
    }

    os_profile {
        computer_name = "hostname"
        admin_username = "applaudoadmin"
        admin_password = "Applaudo2020"
         
    }
    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
        path = "/home/applaudoadmin/.ssh/authorized_keys"
        key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDMNXRjwh1f+q0CxDVEoNtFF173alC3lgkhWgZD/u3fihcVSepvD9rxFb4FcfFlodxByqs+hg02BhKSl0kqt+7xrrWSSQ4CaPWz7Bo8dcPtbwzpq4t1FAcbG1WXAYX8xMq79nGZbzJXv53i8EfMOrtHrjPwHVopHzciQkRvFXglRvLPav0qhSOaMRSpLaKAj1ZxGIKTf/eqBM+6BeE6POSmajtxc94sEEo7bwAimu9DMfPIKSlj0HIvg5DuKvwrhbTf+J4HOG7KDjBkYVcNE3WWiSV+qIEiDeynvlBEsJbMKDHtw6OfTN82N4WseaR+0BYtz3yEA4zwA93l5j1M56fB"
        }
    }
    
	tags = azurerm_resource_group.Monitoring.tags
  }


resource "azurerm_log_analytics_workspace" "External" {
    name = "External"
    location = azurerm_resource_group.Monitoring.location
    resource_group_name = azurerm_resource_group.Monitoring.name
    sku = "PerGB2018"
    retention_in_days = 30
}
resource "azurerm_virtual_machine_extension" "AZ-Extension-LogAnalytics" {
  name                       = "AZ-Log-Analytics"
  location                   = azurerm_resource_group.Monitoring.location
  resource_group_name        = azurerm_resource_group.Monitoring.name
  virtual_machine_name       = azurerm_virtual_machine.VM01.name
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "OmsAgentForLinux"
  type_handler_version       = "1.12"
  auto_upgrade_minor_version = false

  settings = <<SETTINGS
 {
        "workspaceId":"${azurerm_log_analytics_workspace.External.workspace_id}"
}
SETTINGS
protected_settings = <<PROTECTED_SETTINGS
 {
        "workspaceKey":"${azurerm_log_analytics_workspace.External.primary_shared_key}"

}
PROTECTED_SETTINGS

}


output "Vnet-id" {
  value = azurerm_virtual_network.Monitoring-Vnet.id
}
 
output "Workspaceid" {
  value = azurerm_log_analytics_workspace.External.id
}

output "Workspacekey" {
  value = azurerm_log_analytics_workspace.External.primary_shared_key
}
output "PublicIPId" {
  value = azurerm_public_ip.VM01-PIP.id
}






