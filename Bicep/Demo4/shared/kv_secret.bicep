param envSuffix string 
param vmName string
param projectName string
resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: 'kv-${projectName}-${substring(uniqueString(subscription().subscriptionId),0,6)}${envSuffix}'
  scope: resourceGroup('rg-${projectName}-management${envSuffix}')
}

resource kv_secret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: '${keyVault.name}/${vmName}'
  properties: {
    value: '${uniqueString(resourceGroup().id)}${uniqueString(resourceGroup().name)}B!'
  }
}

output secretUri string = kv_secret.properties.secretUri
