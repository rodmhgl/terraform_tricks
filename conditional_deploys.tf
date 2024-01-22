variable "resource_groups" {
  type = map(object({
    enabled  = bool
    location = string
  }))
  description = "A map of resource groups to create."
  default = {
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
  # Dynamically generate a map of enabled resource groups
  # This logic could also be moved to a locals block if preferred
  # for_each = local.enabled_resource_groups
  for_each = {
    for k, v in var.resource_groups :
    k => v if v.enabled == true
  }

  name     = each.key
  location = each.value.location
  tags     = local.tags
}

output "conditional_deploys_resource_group_names" {
  value = [for k, v in azurerm_resource_group.conditional_deploys : k]
}
