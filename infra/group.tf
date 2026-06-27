# AVD User group and role assignments
resource "azuread_group" "avd_users" {
  display_name     = "${var.prj}-${var.env}-avd-users"
  security_enabled = true
}

resource "azurerm_role_assignment" "avd_users_app_group" {
  scope                = azurerm_virtual_desktop_application_group.avd_dag.id
  role_definition_name = "Desktop Virtualization User"
  principal_id         = azuread_group.avd_users.object_id
}

resource "azurerm_role_assignment" "avd_users_vm_login" {
  scope                = azurerm_resource_group.avd_rg.id
  role_definition_name = "Virtual Machine User Login"
  principal_id         = azuread_group.avd_users.object_id
}

# AVD Admin group and role assignments
resource "azuread_group" "avd_admins" {
  display_name     = "${var.prj}-${var.env}-avd-admins"
  security_enabled = true
}

resource "azurerm_role_assignment" "avd_admins_app_group" {
  scope                = azurerm_virtual_desktop_application_group.avd_dag.id
  role_definition_name = "Desktop Virtualization User"
  principal_id         = azuread_group.avd_admins.object_id
}

resource "azurerm_role_assignment" "avd_admins_vm_login" {
  scope                = azurerm_resource_group.avd_rg.id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = azuread_group.avd_admins.object_id
}
