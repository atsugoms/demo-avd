# Azure Virtual Desktop Resources

# Host Pool
resource "azurerm_virtual_desktop_host_pool" "avd_hostpool" {
  resource_group_name      = azurerm_resource_group.avd_rg.name
  location                 = azurerm_resource_group.avd_rg.location
  name                     = "${var.prj}-${var.env}-hostpool"
  friendly_name            = "${var.prj}-${var.env} AVD Host Pool"
  description              = "AVD Host Pool for ${var.prj}-${var.env}"
  type                     = "Pooled"
  load_balancer_type       = "BreadthFirst"
  validate_environment     = false
  scheduled_agent_updates {
    enabled = false
  }
}

# Desktop Application Group
resource "azurerm_virtual_desktop_application_group" "avd_dag" {
  resource_group_name          = azurerm_resource_group.avd_rg.name
  location                     = azurerm_resource_group.avd_rg.location
  name                         = "${var.prj}-${var.env}-dag"
  friendly_name                = "${var.prj}-${var.env} Desktop Application Group"
  description                  = "Desktop Application Group for ${var.prj}-${var.env}"
  type                         = "Desktop"
  host_pool_id                 = azurerm_virtual_desktop_host_pool.avd_hostpool.id
  depends_on                   = [azurerm_virtual_desktop_host_pool.avd_hostpool]
}

# AVD Workspace
resource "azurerm_virtual_desktop_workspace" "avd_workspace" {
  resource_group_name = azurerm_resource_group.avd_rg.name
  location            = azurerm_resource_group.avd_rg.location
  name                = "${var.prj}-${var.env}-workspace"
  friendly_name       = "${var.prj}-${var.env} Workspace"
  description         = "AVD Workspace for ${var.prj}-${var.env}"
}

# Associate Application Group with Workspace
resource "azurerm_virtual_desktop_workspace_application_group_association" "avd_workspace_dag_assoc" {
  workspace_id             = azurerm_virtual_desktop_workspace.avd_workspace.id
  application_group_id     = azurerm_virtual_desktop_application_group.avd_dag.id
  depends_on               = [azurerm_virtual_desktop_application_group.avd_dag]
}

# Host Pool Registration Info (for joining session hosts)
resource "azurerm_virtual_desktop_host_pool_registration_info" "avd_registration_info" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.avd_hostpool.id
  expiration_date = timeadd(timestamp(), "168h") # 7 days
}

# Session Host NIC
resource "azurerm_network_interface" "avd_sessionhost_nic" {
  count               = var.session_host_count
  name                = format("%s-%s-win11ent-nic%02d", var.prj, var.env, count.index + 1)
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.hub_default_snet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Session Host VM
resource "azurerm_windows_virtual_machine" "avd_sessionhost_win11ent" {
  count               = var.session_host_count
  name                = format("%s-%s-win11ent%02d", var.prj, var.env, count.index + 1)
  computer_name       = format("win11ent%02d", count.index + 1)
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
  size                = var.session_host_vm_size
  admin_username      = var.session_host_admin_username
  admin_password      = var.session_host_admin_password
  network_interface_ids = [
    azurerm_network_interface.avd_sessionhost_nic[count.index].id
  ]

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-25h2-avd"
    version   = "latest"
  }

  license_type = "Windows_Client"
}

# Entra ID join (without Intune enrollment)
resource "azurerm_virtual_machine_extension" "avd_sessionhost_aadlogin" {
  count                      = var.session_host_count
  name                       = "AADLoginForWindows"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd_sessionhost_win11ent[count.index].id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "2.2"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
{
  "mdmId": ""
}
SETTINGS
}

# Register VM as AVD session host
resource "azurerm_virtual_machine_extension" "avd_sessionhost_register" {
  count                      = var.session_host_count
  name                       = "DSC"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd_sessionhost_win11ent[count.index].id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
{
  "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02714.342.zip",
  "configurationFunction": "Configuration.ps1\\AddSessionHost",
  "properties": {
    "hostPoolName": "${azurerm_virtual_desktop_host_pool.avd_hostpool.name}"
  }
}
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
{
  "properties": {
    "registrationInfoToken": "${azurerm_virtual_desktop_host_pool_registration_info.avd_registration_info.token}"
  }
}
PROTECTED_SETTINGS

  depends_on = [
    azurerm_virtual_machine_extension.avd_sessionhost_aadlogin,
    azurerm_virtual_desktop_host_pool_registration_info.avd_registration_info
  ]
}
