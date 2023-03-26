param administratorLogin string
param envSuffix string
param serverName string = 'sql-${projectName}-${substring(uniqueString(subscription().subscriptionId), 0, 6)}${envSuffix}'
param location string = resourceGroup().location
@secure()
param administratorLoginPassword string
param allowAzureIps bool = true
param elasticPoolName string = 'sqldb-${projectName}-pool${envSuffix}'
param skuName string = 'BasicPool'
param tier string = 'Basic'
param poolLimit int = 50
param poolSize int = 5242880000
param perDatabasePerformanceMin int = 0
param perDatabasePerformanceMax int = 5
param zoneRedundant bool = false
param licenseType string = 'LicenseIncluded'
param elasticPoolTags object = {}
param maintenanceConfigurationId string = ''
param projectName string

resource sqlServer 'Microsoft.Sql/servers@2020-11-01-preview' = {
  name: serverName
  location: location
  properties: {
    version: '12.0'
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
  }
}

resource serverName_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2021-02-01-preview' = if (allowAzureIps) {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
  dependsOn: [
    sqlServer
  ]
}

resource elasticPool 'Microsoft.Sql/servers/elasticpools@2021-02-01-preview' = {
  parent: sqlServer
  location: location
  name: elasticPoolName
  sku: {
    name: skuName
    tier: tier
    capacity: poolLimit
  }
  properties: {
    perDatabaseSettings: {
      minCapacity: perDatabasePerformanceMin
      maxCapacity: perDatabasePerformanceMax
    }
    maxSizeBytes: poolSize
    zoneRedundant: zoneRedundant
    licenseType: licenseType
  }
  dependsOn: [
    sqlServer
  ]
}

output sqlID string = sqlServer.id
