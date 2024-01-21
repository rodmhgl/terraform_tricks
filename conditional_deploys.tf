locals {
  resource_groups = {
    rg-app-dev-use = {
      enabled  = true
      location = "East US"
    }
    rg-app-dev-usw3 = {
      enabled  = false
      location = "West US 3"
    }
  }
}

resource "azurerm_resource_group" "conditional_deploys" {
  for_each = {
    for k, v in local.resource_groups :
    k => v if v.enabled == true
  }

  location = each.value.location
  name     = each.key
  tags     = local.tags
}

output "conditional_deploys_resource_groups" {
  value = { for k, v in azurerm_resource_group.conditional_deploys : k => v }
}
