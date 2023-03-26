param location string = resourceGroup().location
param vmSize string = 'Standard_B2s'
param osDiskType string = 'Premium_LRS'
param image string
param vmName string
param envSuffix string
param vmCount int
param ilbProbe string
param nsgID string
param subnetRef string
param loadBalancerBackendAddressPools string
param diagStorage string
param projectName string

@description('only for testing')
@secure()
param adminPassword string = 'jdsfgkJHFFK34@!'

resource virtualMachineScaleSets_ilcv_name_resource 'Microsoft.Compute/virtualMachineScaleSets@2021-03-01' = {
  name: vmName
  location: location

  sku: {
    name: vmSize
    tier: 'Standard'
    capacity: vmCount
  }
  zones: [
    '2'
  ]
  properties: {
    singlePlacementGroup: true
    upgradePolicy: {
      mode: 'Manual'
    }
    scaleInPolicy: {
      rules: [
        'Default'
      ]
    }
    virtualMachineProfile: {
      osProfile: {
        adminUsername: 'Brewadmin'
        adminPassword: adminPassword
        computerNamePrefix: vmName
      }
      storageProfile: {
        osDisk: {
          osType: 'Windows'
          createOption: 'FromImage'
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: osDiskType
          }
        }
        imageReference: {
          id: image
        }
      }
      networkProfile: {
        healthProbe: {
          id: ilbProbe
        }
        networkInterfaceConfigurations: [
          {
            name: 'vnet-${projectName}${envSuffix}-nic'
            properties: {
              primary: true
              enableAcceleratedNetworking: false
              networkSecurityGroup: {
                id: nsgID
              }
              dnsSettings: {
                dnsServers: []
              }
              enableIPForwarding: false
              ipConfigurations: [
                {
                  name: 'vnet-${projectName}${envSuffix}-nic-defaultIpConfiguration'
                  properties: {
                    primary: true
                    subnet: {
                      id: subnetRef
                    }
                    privateIPAddressVersion: 'IPv4'
                    loadBalancerBackendAddressPools: [
                      {
                        id: loadBalancerBackendAddressPools
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
          storageUri: diagStorage
        }
      }
    }
    overprovision: true
    doNotRunExtensionsOnOverprovisionedVMs: false
    platformFaultDomainCount: 5
    automaticRepairsPolicy: {
      enabled: false
      gracePeriod: 'PT10M'
    }
  }
}
