param vnetName string
param subnetName string
param subnetAddressPrefix string
param nsgId string = ''
param routeTableId string = ''

resource nsgAttachment 'Microsoft.Network/virtualNetworks/subnets@2020-07-01' = {
  name: subnetName
  properties: {
    addressPrefix: subnetAddressPrefix
    networkSecurityGroup: nsgId == '' ? null : {
      id: nsgId
    }
    routeTable: routeTableId == '' ? null : {
      id: routeTableId
    }
  }
}
