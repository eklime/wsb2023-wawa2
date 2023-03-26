/**/

targetScope = 'subscription'
param envSuffix string
param location string = 'westeurope'
param projectName string

var resourceGroups = [
  'rg-${projectName}-batch'
  'rg-${projectName}-storage'
  'rg-${projectName}-db'

]
resource rgs 'Microsoft.Resources/resourceGroups@2021-04-01' = [for rg in resourceGroups: {
  name: '${rg}${envSuffix}'
  location: location
}]

resource net_rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${projectName}-networking${envSuffix}'
  location: location
}

module vnet './network.bicep' = {
  name: 'vNET'
  scope: net_rg
  params: {
    vnetaddressspace: '12'
    envSuffix: envSuffix
    location: location
    projectName: projectName
  }
}

module storage './storage.bicep' = {
  scope: resourceGroup('rg-${projectName}-storage${envSuffix}')
  name: 'storage'
  params: {
    vnet_subnet: '${vnet.outputs.client_vnet_id}/subnets/private-endpoint'
    private_dns_zone_name_id: vnet.outputs.private_dns_zone_name_id
    envSuffix: envSuffix
    location: location
    projectName: projectName
  }
}


output diagStorageBlob string = storage.outputs.diagStorageBlob
output privateDNSSQLName string = vnet.outputs.private_dns_sql_zone_name_id
