/**/

targetScope = 'subscription'
param envSuffix string 
param location string = 'westeurope'
param diagStorage string

param privateDNSSQLName string
param projectName string

module batch '../batch/batch_deploy.bicep' =  {
  name: 'batch'
  params: {
    envSuffix: envSuffix
    diagStorage: diagStorage
    projectName: projectName
    location: location
  }
}

module sql './sql_deployment.bicep' = {
  scope: resourceGroup('rg-${projectName}-db${envSuffix}')
  name: 'sql'
  params: {
    serverLocation: location
    serverName: 'sql-${projectName}-${substring(uniqueString(subscription().subscriptionId), 0, 6)}${envSuffix}'
    privateDNSSQLName: privateDNSSQLName
    envSuffix: envSuffix
    location: location
    projectName: projectName
  }
}


