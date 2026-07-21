# resource "azurerm_bastion_host" "hub_bastion" {
#   name                = "${var.prj}-${var.env}-bastion"
#   location            = azurerm_resource_group.avd_rg.location
#   resource_group_name = azurerm_resource_group.avd_rg.name

#   sku                = "Developer"
#   virtual_network_id = azurerm_virtual_network.vnet.id

#   tags = {
#     project     = var.prj
#     environment = var.env
#     role        = "bastion"
#   }
# }
