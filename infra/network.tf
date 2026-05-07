resource "azurerm_virtual_network" "hub_vnet" {
  name                = "${var.prj}-${var.env}-hub-vnet"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "hub_default_snet" {
  name                 = "${var.prj}-${var.env}-hub-default-snet"
  resource_group_name  = azurerm_resource_group.avd_rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_virtual_network" "spoke_vnet" {
  name                = "${var.prj}-${var.env}-spoke-vnet"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "spoke_default_snet" {
  name                 = "${var.prj}-${var.env}-spoke-default-snet"
  resource_group_name  = azurerm_resource_group.avd_rg.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}