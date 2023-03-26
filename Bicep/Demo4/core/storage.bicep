param location string = resourceGroup().location
param vnet_subnet string
param private_dns_zone_name_id string
param envSuffix string
param projectName string

resource clientStorage 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: 'stg${uniqueString(resourceGroup().id)}'
  location: location
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    accessTier: 'Hot'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: vnet_subnet
          action: 'Allow'
        }
      ]
      ipRules: []
    }
  }
  sku: {
    name: 'Standard_LRS'
  }
}

resource file_share 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-02-01' = {
  name: '${clientStorage.name}/default/share'
  properties: {
    shareQuota: 10
    enabledProtocols: 'SMB'
    accessTier: 'TransactionOptimized'
  }
}

module private_endpoint 'storage_private_endpoint.bicep' = {
  scope: resourceGroup('rg-${projectName}-networking${envSuffix}')
  name: 'storage_private_endpoint'
  params: {
    vnet_subnet: vnet_subnet
    clientStorage: clientStorage.id
    private_dns_zone_name_id: private_dns_zone_name_id
    location: location
  }
}

resource diagStorage 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: 'stgdiag${uniqueString(resourceGroup().id)}'
  location: location
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    accessTier: 'Hot'
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
  }
  sku: {
    name: 'Standard_LRS'
  }
}

output diagStorageBlob string = diagStorage.properties.primaryEndpoints.blob
