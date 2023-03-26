param location string = resourceGroup().location
param vnet_subnet string
param clientStorage string
param private_dns_zone_name_id string

resource privateEndpoints 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: 'files'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'files'
        properties: {
          privateLinkServiceId: clientStorage
          groupIds: [
            'file'
          ]
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    subnet: {
      id: vnet_subnet
    }
    customDnsConfigs: []
  }
}

resource privateEndpoints_zone 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  parent: privateEndpoints
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-file-core-windows-net'
        properties: {
          privateDnsZoneId: private_dns_zone_name_id
        }
      }
    ]
  }
}
