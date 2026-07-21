resource "azurerm_network_security_group" "default_snet_nsg" {
  name                = "${var.prj}-${var.env}-vnet-default-snet-nsg"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
}

resource "azurerm_network_security_rule" "default_snet_allow_rdp_from_bastion" {
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
  network_security_group_name = azurerm_network_security_group.default_snet_nsg.name
}

resource "azurerm_subnet_network_security_group_association" "default_snet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.hub_default_snet.id
  network_security_group_id = azurerm_network_security_group.default_snet_nsg.id
}

resource "azurerm_network_security_group" "private_endpoint_snet_nsg" {
  name                = "${var.prj}-${var.env}-vnet-pe-snet-nsg"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
}

resource "azurerm_subnet_network_security_group_association" "private_endpoint_snet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.private_endpoint_snet.id
  network_security_group_id = azurerm_network_security_group.private_endpoint_snet_nsg.id
}

