targetScope = 'subscription'
param envSuffix string = '-prod'
param location string
param kv_access_objectID string = '16abf7a2-80f4-445e-85d0-6ba73d0b3e5c'
param deploy_kv bool = true
param projectName string

resource mngt_rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${projectName}-management${envSuffix}'
  location: location
}

module log './log_analytics.bicep' = {
  name: 'logAnalytics'
  scope: mngt_rg
  params: {
    envSuffix: envSuffix
    location: location
    projectName: projectName
  }
}

module kv './kv_deployment.bicep' = if (deploy_kv == true) {
  name: 'kv'
  dependsOn: [
    log
  ]
  scope: mngt_rg
  params: {
    keyVaultName: 'kv-${toLower(projectName)}-${substring(uniqueString(subscription().subscriptionId), 0, 6)}${envSuffix}'
    objectId: kv_access_objectID
    workspaceId: log.outputs.workspaceresourceid
    envSuffix: envSuffix
    location: location
    projectName: projectName
  }
}


