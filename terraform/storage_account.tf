locals {
  profiles_storage_account_name = substr(
    "${replace(var.prj, "-", "")}${replace(var.env, "-", "")}profilessa",
    0,
    24
  )

  profiles_storage_app_display_name = "[Storage Account] ${local.profiles_storage_account_name}.file.core.windows.net"
}

# Create a storage account for AVD FSLogix profile containers
resource "azurerm_storage_account" "profiles" {
  name                     = local.profiles_storage_account_name
  resource_group_name      = azurerm_resource_group.avd_rg.name
  location                 = azurerm_resource_group.avd_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  public_network_access_enabled = false
  shared_access_key_enabled     = true

  azure_files_authentication {
    directory_type = "AADKERB"
  }

  tags = {
    SecurityControl = "Ignore"
  }
}

resource "azurerm_storage_share" "profiles" {
  name               = "profiles"
  storage_account_id = azurerm_storage_account.profiles.id
  quota              = 100
  enabled_protocol   = "SMB"
}

# Create a private endpoint for the storage account's file service
resource "azurerm_private_dns_zone" "storage_file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.avd_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_file_vnet_link" {
  name                  = "${var.prj}-${var.env}-storage-file-dns-link"
  resource_group_name   = azurerm_resource_group.avd_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_file.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_endpoint" "storage_file" {
  name                          = "${var.prj}-${var.env}-st-file-pe"
  custom_network_interface_name = "${var.prj}-${var.env}-st-file-nic"
  location                      = azurerm_resource_group.avd_rg.location
  resource_group_name           = azurerm_resource_group.avd_rg.name
  subnet_id                     = azurerm_subnet.private_endpoint_snet.id

  private_service_connection {
    name                           = "${var.prj}-${var.env}-st-file-psc"
    private_connection_resource_id = azurerm_storage_account.profiles.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "storage-file-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_file.id]
  }
}

# Grant delegated permissions to the storage account's service principal for Microsoft Graph API
data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "microsoft_graph" {
  client_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
}

data "azuread_service_principal" "profiles_storage_app" {
  display_name = local.profiles_storage_app_display_name

  depends_on = [azurerm_storage_account.profiles]
}

resource "azuread_service_principal_delegated_permission_grant" "profiles_storage_graph_consent" {
  service_principal_object_id          = data.azuread_service_principal.profiles_storage_app.object_id
  resource_service_principal_object_id = data.azuread_service_principal.microsoft_graph.object_id
  claim_values                         = ["openid", "profile", "User.Read"]
}
