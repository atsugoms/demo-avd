resource "azurerm_resource_group" "avd_rg" {
  name     = "${var.prj}-${var.env}-rg"
  location = "Japan East"
}
