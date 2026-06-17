resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prj}-${var.env}-vnet"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "hub_default_snet" {
  name                 = "${var.prj}-${var.env}-default-snet"
  resource_group_name  = azurerm_resource_group.avd_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
