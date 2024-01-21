# Azure example of flattening a map of maps into a list of maps
# Azure-ized version of https://developer.hashicorp.com/terraform/language/functions/flatten

provider "azurerm" {
  features {}
}

variable "networks" {
  type = map(object({
    cidr_block = string
    subnets    = map(object({ cidr_block = string }))
  }))
  default = {
    "private" = {
      cidr_block = "10.1.0.0/16"
      subnets = {
        "db1" = {
          cidr_block = "10.1.0.0/24"
        }
        "db2" = {
          cidr_block = "10.1.1.0/24"
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
  network_subnets = flatten([
    for network_key, network in var.networks : [
      for subnet_key, subnet in network.subnets : {
        network_key  = network_key
        subnet_key   = subnet_key
        network_id   = azurerm_virtual_network.this[network_key].id
        network_name = azurerm_virtual_network.this[network_key].name
        cidr_block   = subnet.cidr_block
      }
    ]
  ])
}

resource "azurerm_resource_group" "this" {
  location = "eastus"
  name     = "rg-app-network-dev-use"
  tags     = local.tags
}

resource "azurerm_virtual_network" "this" {
  # For the virtual_network resource, we can use var.networks directly.
  for_each = var.networks

  name                = each.key
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [each.value.cidr_block]
  tags                = local.tags
}

resource "azurerm_subnet" "this" {
  # local.network_subnets is a list, so we must now project it into a map
  # where each key is unique. We'll combine the network and subnet keys to
  # produce a single unique key per instance.
  for_each = {
    for subnet in local.network_subnets :
    "${subnet.network_key}.${subnet.subnet_key}" => subnet
  }

  name                 = each.key
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = each.value.network_name
  address_prefixes     = [each.value.cidr_block]
}
