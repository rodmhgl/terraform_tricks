# Azure example of flattening a map of maps into a list of maps
# Azure-ized version of https://developer.hashicorp.com/terraform/language/functions/flatten
variable "networks" {
  type = map(object({
    cidr_block = string
    subnets = map(object({
      cidr_block = string
      nsg = optional(map(object({
        rules = optional(map(object({
          priority                   = number,
          direction                  = string,
          access                     = string,
          protocol                   = string,
          source_port_range          = string,
          destination_port_range     = string,
          source_address_prefix      = string,
          destination_address_prefix = string,
        })), {})
      })), {})
    }))
  }))
  default = {
    "private" = {
      cidr_block = "10.1.0.0/16"
      subnets = {
        "db1" = {
          cidr_block = "10.1.0.0/24"
          nsg = {
            "db1-nsg" = {
              rules = {
                "GatewayManager" = {
                  name                       = "GatewayManager"
                  priority                   = 1001
                  direction                  = "Inbound"
                  access                     = "Allow"
                  protocol                   = "Tcp"
                  source_port_range          = "*"
                  destination_port_range     = "443"
                  source_address_prefix      = "GatewayManager"
                  destination_address_prefix = "*"
                }
                "Internet-Bastion-PublicIP" = {
                  name                       = "Internet-Bastion-PublicIP"
                  priority                   = 1002
                  direction                  = "Inbound"
                  access                     = "Allow"
                  protocol                   = "Tcp"
                  source_port_range          = "*"
                  destination_port_range     = "443"
                  source_address_prefix      = "*"
                  destination_address_prefix = "*"
                }
              }
            }
          }
        }
        "db2" = {
          cidr_block = "10.1.1.0/24"
          nsg        = {}
        }
      }
    },
    "public" = {
      cidr_block = "10.2.0.0/16"
      subnets = {
        "webserver" = {
          cidr_block = "10.2.0.0/24"
        }
        "email_server" = {
          cidr_block = "10.2.1.0/24"
        }
      }
    }
    "dmz" = {
      cidr_block = "10.3.0.0/16"
      subnets = {
        "firewall" = {
          cidr_block = "10.3.0.0/24"
        }
      }
    }
  }
}

locals {
  # flatten ensures that this local value is a flat list of objects,
  # rather than a list of lists of objects.
  # We project the result from flatten into a map
  # where each key is unique.
  # We'll combine the network and subnet keys to
  # produce a single unique key per instance.
  network_subnets = {
    for subnet in flatten([
      for network_key, network in var.networks : [
        for subnet_key, subnet in network.subnets : {
          network_key  = network_key
          subnet_key   = subnet_key
          network_id   = azurerm_virtual_network.this[network_key].id
          network_name = azurerm_virtual_network.this[network_key].name
          cidr_block   = subnet.cidr_block
          nsg          = subnet.nsg
        }
      ]
    ]) : "${subnet.network_key}.${subnet.subnet_key}" => subnet
  }

  subnet_nsgs = {
    for nsg in flatten([
      for subnet_key, subnet in local.network_subnets : [
        for nsg_key, nsg in subnet.nsg : {
          subnet_key  = "${subnet.network_key}.${subnet.subnet_key}"
          network_key = subnet.network_key
          name        = nsg_key
          nsg_rules   = nsg.rules
        }
      ]
    ]) : nsg.name => nsg
  }
}

resource "azurerm_resource_group" "flatten" {
  location = "eastus"
  name     = "rg-app-network-dev-use"
  tags     = local.tags
}

resource "azurerm_virtual_network" "this" {
  # For the virtual_network resource, we can use var.networks directly.
  for_each = var.networks

  name                = each.key
  location            = azurerm_resource_group.flatten.location
  resource_group_name = azurerm_resource_group.flatten.name
  address_space       = [each.value.cidr_block]
  tags                = local.tags
}

resource "azurerm_subnet" "this" {
  for_each = local.network_subnets

  name                 = each.key
  resource_group_name  = azurerm_resource_group.flatten.name
  virtual_network_name = each.value.network_name
  address_prefixes     = [each.value.cidr_block]
}

resource "azurerm_network_security_group" "this" {
  for_each = local.subnet_nsgs

  location            = azurerm_resource_group.flatten.location
  name                = each.key
  resource_group_name = azurerm_resource_group.flatten.name
  tags                = local.tags
  dynamic "security_rule" {
    for_each = each.value.nsg_rules
    content {
      name                       = security_rule.key
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }

}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = local.subnet_nsgs

  subnet_id                 = azurerm_subnet.this[each.value.subnet_key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}
