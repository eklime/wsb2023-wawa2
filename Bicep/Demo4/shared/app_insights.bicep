param type string = 'web'
param requestSource string = 'IbizaAIExtension'
param workspaceResourceId string
param location string = resourceGroup().location
param envSuffix string


resource AppInsights_resource 'microsoft.insights/components@2020-02-02-preview' = {
  name: 'appins-${projectName}${envSuffix}'
  location: location
  kind: 'other'
  properties: {
    Application_Type: type
    Request_Source: requestSource
    WorkspaceResourceId: workspaceResourceId
  }
  dependsOn: []
}
