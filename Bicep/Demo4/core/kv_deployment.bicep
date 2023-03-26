param keyVaultName string
param location string = resourceGroup().location
param envSuffix string 
param projectName string

param date string = utcNow()

@description('Specifies whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault.')
@allowed([
  true
  false
])
param enabledForDeployment bool = false

@description('Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys.')
@allowed([
  true
  false
])
param enabledForDiskEncryption bool = false

@description('Specifies whether Azure Resource Manager is permitted to retrieve secrets from the key vault.')
@allowed([
  true
  false
])
param enabledForTemplateDeployment bool = true

@description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.')
param tenantId string = subscription().tenantId

@description('Specifies the object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies. Get it by using Get-AzADUser or Get-AzADServicePrincipal cmdlets.')
param objectId string = ''

@description('Specifies the permissions to keys in the vault. Valid values are: all, encrypt, decrypt, wrapKey, unwrapKey, sign, verify, get, list, create, update, import, delete, backup, restore, recover, and purge.')
param keysPermissions array = [
  'all'
]

@description('Specifies the permissions to secrets in the vault. Valid values are: all, get, list, set, delete, backup, restore, recover, and purge.')
param secretsPermissions array = [
  'all'
]

@description('Specifies whether the key vault is a standard vault or a premium vault.')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'
param workspaceId string = ''

resource keyVaultName_resource 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  location: location
  tags: {
    displayName: 'KeyVault'
  }
  properties: {
    enabledForDeployment: enabledForDeployment
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    tenantId: tenantId
    accessPolicies: [
      {
        objectId: objectId
        tenantId: tenantId
        permissions: {
          keys: keysPermissions
          secrets: secretsPermissions
        }
      }
      
    ]
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: 'log-${projectName}${envSuffix}'
  scope: resourceGroup('rg-${projectName}-management${envSuffix}')
}

resource keyVaultDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: keyVaultName_resource
  name: 'sendToLAWorkspace'
  dependsOn: [
    logAnalytics
  ]
  properties: {
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: workspaceId
  }
}

resource kv_vmBrewadmin 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  parent: keyVaultName_resource
  name: 'vmBrewadmin'
  properties: {
    value: '${skip(base64(uniqueString(resourceGroup().id, date)), 3)}!${uniqueString(resourceGroup().name)}'
  }
}

resource kv_logAnalyticsID 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  parent: keyVaultName_resource
  name: 'logAnalyticsID'
  properties: {
    value: workspaceId
  }
}

resource kv_sqlBrewadmin 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  parent: keyVaultName_resource
  name: 'sqlBrewadmin'
  properties: {
    value: '${skip(base64(uniqueString(resourceGroup().id, date)), 3)}!${uniqueString(subscription().id)}'
  }
}
