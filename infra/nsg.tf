resource "azurerm_network_security_group" "hub_default_snet_nsg" {
  name                = "${var.prj}-${var.env}-hub-default-snet-nsg"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
}

resource "azurerm_network_security_rule" "hub_default_snet_allow_rdp_from_bastion" {
  name                        = "AllowRdpFromAzureBastion"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.avd_rg.name
  network_security_group_name = azurerm_network_security_group.hub_default_snet_nsg.name
}

resource "azurerm_subnet_network_security_group_association" "hub_default_snet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.hub_default_snet.id
  network_security_group_id = azurerm_network_security_group.hub_default_snet_nsg.id
}

resource "azurerm_network_security_group" "spoke_default_snet_nsg" {
  name                = "${var.prj}-${var.env}-spoke-default-snet-nsg"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
}

resource "azurerm_subnet_network_security_group_association" "spoke_default_snet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.spoke_default_snet.id
  network_security_group_id = azurerm_network_security_group.spoke_default_snet_nsg.id
}