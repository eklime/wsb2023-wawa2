param name string
param IPaddress string
param envSuffix string
param privateDNSName string = 'private.brew'
param projectName string

resource privateDNS 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDNSName
  scope: resourceGroup('rg-${projectName}-networking${envSuffix}')
}

resource privateDnsZones_private_brew_name_ilb_rv_prod 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  name: '${privateDNS.name}/${name}'
  properties: {
    ttl: 10
    aRecords: [
      {
        ipv4Address: IPaddress
      }
    ]
  }
  dependsOn: [
    privateDNS
  ]
}
