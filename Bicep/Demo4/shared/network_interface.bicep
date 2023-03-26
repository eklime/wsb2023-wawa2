param location string = resourceGroup().location
param networkInterfaceName string
param subnetRef string
param privateIPAllocationMethod string = 'Dynamic'
param loadBalancerBackendAddressPools string

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
          loadBalancerBackendAddressPools: [
            {
              id: loadBalancerBackendAddressPools
            }
          ]
        }
      }
    ]
  }
  dependsOn: []
}
