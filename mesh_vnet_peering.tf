# Flatten the maps into a list of maps
# that can be passed directly to the
# azurerm_virtual_network_peering resource.
# Stolen from https://github.com/Azure/terraform-azurerm-hubnetworking
locals {
  east_vnets = {
    east_vnet_one = {
      vnet_name = "vnet-dev-backend-dev-use"
      vnet_id   = "/subscriptions/subid/resourceGroups/east-rg2/providers/Microsoft.Network/virtualNetworks/vnet-dev-backend-dev-use"
    }
    east_vnet_two = {
      vnet_name = "vnet-dev-frontend-dev-use"
      vnet_id   = "/subscriptions/subid/resourceGroups/east-rg2/providers/Microsoft.Network/virtualNetworks/vnet-dev-frontend-dev-use"
    }
  }

  west_vnets = {
    west_vnet_one = {
      vnet_name = "vnet-dev-backend-dev-usw"
      vnet_id   = "/subscriptions/subid/resourceGroups/west-rg2/providers/Microsoft.Network/virtualNetworks/vnet-dev-backend-dev-usw"
    }
    west_vnet_two = {
      vnet_name = "vnet-dev-frontend-dev-usw"
      vnet_id   = "/subscriptions/subid/resourceGroups/west-rg2/providers/Microsoft.Network/virtualNetworks/vnet-dev-frontend-dev-usw"
    }
  }

  peer_map = {
    for peerconfig in flatten([
      for k_src, v_src in local.east_vnets :
      [
        for k_dst, v_dst in local.west_vnets :
        {
          name                         = "${v_src.vnet_name}-${v_dst.vnet_name}"
          src_key                      = k_src
          dst_key                      = k_dst
          virtual_network_name         = v_src.vnet_name
          remote_virtual_network_id    = v_dst.vnet_id
          allow_virtual_network_access = true
          allow_forwarded_traffic      = true
          allow_gateway_transit        = true
          use_remote_gateways          = false
        }
      ]
    ]) : peerconfig.name => peerconfig
  }
}

output "peering_peer_map" {
  description = "Flattens two maps to be passed to the azurerm_virtual_network_peering resource for a mesh peering."
  value       = local.peer_map
}
