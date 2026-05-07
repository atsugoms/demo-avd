resource "azurerm_public_ip" "adds_pip" {
  name                = "${var.prj}-${var.env}-adds-pip"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "adds_nic" {
  name                = "${var.prj}-${var.env}-adds-nic"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.hub_default_snet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.10"
    public_ip_address_id          = azurerm_public_ip.adds_pip.id
  }
}

resource "azurerm_windows_virtual_machine" "adds_vm" {
  name                = "${var.prj}-${var.env}-adds-vm"
  computer_name       = "addssvr"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
  size                = var.adds_vm_size
  admin_username      = var.adds_admin_username
  admin_password      = var.adds_admin_password
  patch_mode          = "AutomaticByPlatform"

  network_interface_ids = [
    azurerm_network_interface.adds_nic.id,
  ]

  os_disk {
    name                 = "${var.prj}-${var.env}-adds-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-datacenter-azure-edition"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    project     = var.prj
    environment = var.env
    role        = "adds"
  }
}
