targetScope = 'subscription'
param envSuffix string = '-prod'
param location string = 'westeurope'
param projectName string = 'CloudBrew'

param core_deployment bool = true
param infra_deployment bool = true

module core './core_deployment.bicep' = if (core_deployment) {
  name: 'core_deployment'
  params: {
    envSuffix: envSuffix
    location: location
    projectName: projectName
  }
}

module infra './infra_deployment.bicep' = if (infra_deployment) {
  name: 'infra_deployment'
  params: {
    diagStorage: core.outputs.diagStorageBlob
    privateDNSSQLName: core.outputs.privateDNSSQLName
    envSuffix: envSuffix
    projectName: projectName
  }
}
