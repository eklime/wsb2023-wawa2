param nsgname string
param location string = resourceGroup().location
param SecRules object

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: nsgname
  location: location
  properties: SecRules
}

output nsgID string = nsg.id
