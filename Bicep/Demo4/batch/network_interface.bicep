param location string = resourceGroup().location
param networkInterfaceName string
param subnetRef string
param privateIPAllocationMethod string = 'Dynamic'

resource batch_publicIP 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: 'pip-batch'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'

  }
}


resource networkInterfaceName_resource 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: privateIPAllocationMethod
          publicIPAddress: {
            id: batch_publicIP.id
          }
        }
      }
    ]
  }
  dependsOn: []
}
