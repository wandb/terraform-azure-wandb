locals {
  dns_name_suffix = "privatelink.azure.clickhouse.cloud"
}

resource "azurerm_private_endpoint" "clickhouse" {
  name                          = "${var.namespace}-clickhouse-pe"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  subnet_id                     = var.private_subnet_id
  custom_network_interface_name = "${var.namespace}-clickhouse-nic"

  private_service_connection {
    name                              = "${var.namespace}-clickhouse-pl"
    private_connection_resource_alias = var.clickhouse_private_endpoint_service_name
    is_manual_connection              = true
    request_message                   = "ClickHouse Private Link"
  }
}

resource "azurerm_private_dns_zone" "clickhouse_cloud_private_link_zone" {
  name                = "${var.clickhouse_region}.${local.dns_name_suffix}"
  resource_group_name = var.resource_group_name
}

data "azurerm_network_interface" "clickhouse_nic" {
  resource_group_name = var.resource_group_name
  name                = azurerm_private_endpoint.clickhouse.network_interface[0].name
}

resource "azurerm_private_dns_a_record" "clickhouse_wildcard" {
  name                = "*"
  zone_name           = azurerm_private_dns_zone.clickhouse_cloud_private_link_zone.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [data.azurerm_network_interface.clickhouse_nic.private_ip_address]
}

resource "azurerm_private_dns_zone_virtual_network_link" "clickhouse_network" {
  name                  = "network-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.clickhouse_cloud_private_link_zone.name
  virtual_network_id    = var.network_id
}
