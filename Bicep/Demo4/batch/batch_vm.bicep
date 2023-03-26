param location string = resourceGroup().location
param vmSize string = 'Standard_B2s'
param vmName string
param namePrefix string
param envSuffix string
param diagStorage string
param projectName string

@secure()
param adminPassword string //= 'jdsfgkJHFFK34'

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' existing = {
  name: 'nic-${namePrefix}'
  scope: resourceGroup('rg-${projectName}-networking${envSuffix}')
}

resource windowsVM 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-smalldisk'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    
    osProfile: {
      adminUsername: 'Brewadmin'
      adminPassword: adminPassword
      computerName: vmName
    }


    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: diagStorage
      }
    }
  }
}
