param location string = resourceGroup().location
param availabilitySetID string
param vmSize string = 'Standard_B2s'
param osDiskType string = 'Premium_LRS'
param image string
param vmName string
param counterID string
param namePrefix string
param envSuffix string
param projectName string

@description('only for testing')
@secure()
param adminPassword string //= 'jdsfgkJHFFK34@!'

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' existing = {
  name: 'nic-${namePrefix}${counterID}'
  scope: resourceGroup('rg-${projectName}-networking${envSuffix}')
}

resource windowsVM 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vmName
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySetID
    }
    hardwareProfile: {
      vmSize: vmSize
    }

    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        id: image
      }
    }
    osProfile: {
      adminUsername: 'Brewadmin'
      adminPassword: adminPassword
      computerName: vmName
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
}
