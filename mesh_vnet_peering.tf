# Flatten the maps into a list of maps
# that can be passed directly to the
# azurerm_virtual_network_peering resource.
# Stolen from https://github.com/Azure/terraform-azurerm-hubnetworking
locals {
  vnets = {
    east_vnet = {
      vnet_name            = "vnet-dev-backend-dev-use"
      vnet_id              = "/subscriptions/subid/resourceGroups/east-rg2/providers/Microsoft.Network/virtualNetworks/vnet-dev-backend-dev-use"
      mesh_peering_enabled = true
    }
    west_vnet = {
      vnet_name            = "vnet-dev-backend-dev-usw"
      vnet_id              = "/subscriptions/subid/resourceGroups/west-rg2/providers/Microsoft.Network/virtualNetworks/vnet-dev-frontend-dev-usw"
      mesh_peering_enabled = true
    }
    central_vnet = {
      vnet_name            = "vnet-dev-backend-dev-usc"
      vnet_id              = "/subscriptions/subid/resourceGroups/central-rg2/providers/Microsoft.Network/virtualNetworks/vnet-dev-backend-dev-usc"
      mesh_peering_enabled = false
    }
    south_vnet = {
      vnet_name            = "vnet-dev-backend-dev-uss"
      vnet_id              = "/subscriptions/subid/resourceGroups/south-rg2/providers/Microsoft.Network/virtualNetworks/vnet-dev-frontend-dev-uss"
      mesh_peering_enabled = true
    }
  }

  /*
    Iterate over each source (`v_src`) and destination virtual network (`v_dst`).
    Create a configuration object for each pair of virtual networks where:
      - the source and destination are different,
      - and the source AND destination have mesh_peering_enabled = true
    This results in a full-mesh peering (between enabled participants)
  */
  peer_map = {
    for peerconfig in flatten([
      for k_src, v_src in local.vnets :
      [
        for k_dst, v_dst in local.vnets :
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
        } if k_src != k_dst && v_dst.mesh_peering_enabled && v_src.mesh_peering_enabled
      ]
    ]) : peerconfig.name => peerconfig
  }
}

output "peering_peer_map" {
  description = "Flattens two maps to be passed to the azurerm_virtual_network_peering resource for a mesh peering."
  value       = local.peer_map
}
