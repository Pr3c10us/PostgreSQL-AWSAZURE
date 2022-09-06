resource "azurerm_resource_group" "replicate_database_group" {
  name     = "api-rg-pro"
  location = "West Europe"
}

resource "azurerm_postgresql_server" "replicate_database_server" {
  name                = "postgresql-server-1"
  location            = azurerm_resource_group.replicate_database_group.location
  resource_group_name = azurerm_resource_group.replicate_database_group.name

  sku_name = "B_Gen5_2"

  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  administrator_login          = "psqladmin"
  administrator_login_password = "H@Sh1CoR3!"
  version                      = "14"
  ssl_enforcement_enabled      = true
}

resource "azurerm_postgresql_database" "replicate_database_database" {
  name                = "exampledb"
  resource_group_name = azurerm_resource_group.replicate_database_group.name
  server_name         = azurerm_postgresql_server.replicate_database_server.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}