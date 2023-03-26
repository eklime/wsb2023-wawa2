param location string = resourceGroup().location
param envSuffix string
param projectName string

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: 'log-${projectName}${envSuffix}'
  location: location
  properties: {
    sku: {
      name: 'Standalone'
    }
    retentionInDays: 30
  }
}

output workspaceid string = logAnalytics.properties.customerId
output workspaceresourceid string = logAnalytics.id
