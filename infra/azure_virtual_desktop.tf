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
