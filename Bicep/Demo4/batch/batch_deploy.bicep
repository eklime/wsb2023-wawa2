targetScope = 'subscription'
param resourceGroupPrefix string = 'rg-${projectName}-batch'
param envSuffix string 
param location string = 'westeurope'
param namePrefix string = 'batch'
param diagStorage string
param projectName string
var resourceGroupName = '${resourceGroupPrefix}${envSuffix}'

//@secure()
//param adminPassword string

resource existingnetwork 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: 'vnet-${projectName}${envSuffix}'
  scope: resourceGroup('rg-${projectName}-networking${envSuffix}')
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-03-01' existing = {
  name: 'nsg-${namePrefix}${envSuffix}'
  scope: resourceGroup('rg-${projectName}-networking${envSuffix}')
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  name: '${existingnetwork.name}/batch'
  scope: resourceGroup('rg-${projectName}-networking${envSuffix}')
}

resource kv 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: 'kv-${projectName}-${substring(uniqueString(subscription().subscriptionId), 0, 6)}${envSuffix}'
  scope: resourceGroup('rg-${projectName}-management${envSuffix}')
}

module network_interface './network_interface.bicep' = {
  scope: resourceGroup('rg-${projectName}-networking${envSuffix}')
  name: 'nic-${namePrefix}'
  params: {
    networkInterfaceName: 'nic-${namePrefix}'
    subnetRef: '${existingnetwork.id}/subnets/batch'
    location: location
  }
}

module recoveryVault '../shared/recovery_vault.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'recoveryVault'
  params: {
    vaultName: 'vault-${namePrefix}${envSuffix}'
    projectName: projectName
  }
}

module vm './batch_vm.bicep' = {
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    network_interface
  ]
  name: namePrefix
  params: {
    vmName: namePrefix
    namePrefix: namePrefix
    envSuffix: envSuffix
    adminPassword: kv.getSecret('vmBrewadmin')
    diagStorage: diagStorage
    location: location
    projectName: projectName
  }
}
