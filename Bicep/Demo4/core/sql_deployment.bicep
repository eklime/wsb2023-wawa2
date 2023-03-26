param envSuffix string
param location string = resourceGroup().location
param administratorLogin string = 'Brewadmin'
@secure()
param administratorLoginPassword string = ''
param administrators object = {}
param serverName string = 'sql-${projectName}-${substring(uniqueString(subscription().subscriptionId), 0, 6)}${envSuffix}'
param serverLocation string
param privateDNSSQLName string
param projectName string

resource kv 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: 'kv-${projectName}-${substring(uniqueString(subscription().subscriptionId), 0, 6)}${envSuffix}'
  scope: resourceGroup('rg-${projectName}-management${envSuffix}')
}

resource existingnetwork 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: 'vnet-${projectName}${envSuffix}'
  scope: resourceGroup('rg-${projectName}-networking${envSuffix}')
}

module sqlserver '../shared/sql_server.bicep' = {
  name: serverName
  params: {
    serverName: serverName
    administratorLogin: administratorLogin
    administratorLoginPassword: kv.getSecret('sqlBrewadmin')
    envSuffix: envSuffix
    location: location
    projectName: projectName
  }
}

module sqlPrivateEndpoint './sql_private_endpoint.bicep' = {
  name: 'pe-${serverName}'
  scope: resourceGroup('rg-${projectName}-networking${envSuffix}')
  params: {
    envSuffix: envSuffix
    vnet_subnet: '${existingnetwork.id}/subnets/private-endpoint'
    sqlID: sqlserver.outputs.sqlID
    private_dns_zone_name_id: privateDNSSQLName
    location: location
    projectName: projectName
  }
}
