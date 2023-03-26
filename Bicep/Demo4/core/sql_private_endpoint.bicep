param location string = resourceGroup().location
param vnet_subnet string
param sqlID string
param private_dns_zone_name_id string
param envSuffix string
param projectName string

var privateEndpoints_name = 'pe-sql-${projectName}${envSuffix}'

resource privateEndpoints 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: 'sql'
  location: location
  tags: {
    project: 'CoudBrew'
    Purpose: 'For fun'
    owner: 'Emil Wasilewski'
  }
  properties: {
    privateLinkServiceConnections: [
      {
        name: privateEndpoints_name
        properties: {
          privateLinkServiceId: sqlID
          groupIds: [
            'sqlServer'
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
        name: 'pe-sql-${projectName}${envSuffix}'
        properties: {
          privateDnsZoneId: private_dns_zone_name_id
        }
      }
    ]
  }
}
