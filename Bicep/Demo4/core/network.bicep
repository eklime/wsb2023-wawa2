param location string = resourceGroup().location
param vnetaddressspace string = '10'
param envSuffix string
param projectName string
var sharedRules = json(loadTextContent('../shared/nsg_config.json')).securityRules

var privateDnsZones_private_name  = 'private.${projectName}'

var client_subnets = [
  {
    name: 'batch'
    subnetPrefix: '10.${vnetaddressspace}.9.0/24'
    serviceEndpoints: null
    privateEndpointNetworkPolicies: 'Enabled'
    networkSecurityGroup: {
      id: nsg_batch.id
    }
  }

  {
    name: 'private-endpoint'
    subnetPrefix: '10.${vnetaddressspace}.11.0/24'
    serviceEndpoints: [
      {
        locations: [
          location
        ]
        service: 'Microsoft.Storage'
      }
    ]
    privateEndpointNetworkPolicies: 'Disabled'
    networkSecurityGroup: null
  }
]

var hub_subnets = [
  {
    name: 'AzureFirewallSubnet'
    subnetPrefix: '10.${vnetaddressspace}.20.0/26'
    networkSecurityGroup: null
    routeTable: null
  }
  {
    name: 'AzureBastionSubnet'
    subnetPrefix: '10.${vnetaddressspace}.20.64/26'
    networkSecurityGroup: {
      id: nsg_hub_bastion.id
    }
    routeTable: null
  }
  {
    name: 'GatewaySubnet'
    subnetPrefix: '10.${vnetaddressspace}.20.128/26'
    networkSecurityGroup: null
    routeTable: null
  }
  {
    name: 'ApplicationGateway'
    subnetPrefix: '10.${vnetaddressspace}.20.192/26'
    networkSecurityGroup: null
    routeTable: null
  }
]

var BatchCustomRules = [
  {
    name: 'Port_8002'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '8002'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 102
      direction: 'Inbound'
      sourcePortRanges: []
      destinationPortRanges: []
      sourceAddressPrefixes: []
      destinationAddressPrefixes: []
    }
  }
  {
    name: 'Port_8000_Range'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '8000-8019'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 103
      direction: 'Inbound'
      sourcePortRanges: []
      destinationPortRanges: []
      sourceAddressPrefixes: []
      destinationAddressPrefixes: []
    }
  }
  {
    name: 'RDP_Public'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '3389'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 110
      direction: 'Inbound'
      sourcePortRanges: []
      destinationPortRanges: []
      sourceAddressPrefixes: []
      destinationAddressPrefixes: []
    }
  }
]

resource client_vnet 'Microsoft.Network/virtualNetworks@2020-07-01' = /*if (subnet_type == '${projectName}')*/ {
  name: 'vnet-${projectName}${envSuffix}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.${vnetaddressspace}.0.0/20'
      ]
    }
    subnets: [for subnet in client_subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.subnetPrefix
        privateEndpointNetworkPolicies: subnet.privateEndpointNetworkPolicies
        privateLinkServiceNetworkPolicies: 'Disabled'
        serviceEndpoints: subnet.serviceEndpoints
        networkSecurityGroup: subnet.networkSecurityGroup
      }
    }]
  }
}

resource hub_vnet 'Microsoft.Network/virtualNetworks@2020-07-01' = /*if (subnet_type == 'hub')*/ {
  name: 'vnet-hub${envSuffix}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.${vnetaddressspace}.20.0/24'
      ]
    }
    subnets: [for subnet in hub_subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.subnetPrefix
        networkSecurityGroup: subnet.networkSecurityGroup
        routeTable: subnet.routeTable
      }
    }]
  }
}

resource peering_from_hub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  name: '${hub_vnet.name}/hub_to_${projectName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: client_vnet.id
    }
  }

}

resource peering_to_hub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  name: '${client_vnet.name}/${projectName}_to_hub'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hub_vnet.id
    }
  }

}

resource existingnetworksubnet 'Microsoft.Network/virtualNetworks/subnets@2021-03-01' existing = {
  name: '${hub_vnet.name}/ApplicationGateway'
  scope: resourceGroup('rg-${projectName}-networking${envSuffix}')
}

resource nsg_batch 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'nsg-batch${envSuffix}'
  location: location
  properties: {
    securityRules: concat(sharedRules, BatchCustomRules)
  }
}

resource nsg_hub_bastion 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'nsg-hub-bastion${envSuffix}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowFromInternet'
        properties: {
          direction: 'Inbound'
          protocol: 'Tcp'
          access: 'Allow'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          sourcePortRange: '*'
          priority: 120
          description: 'Allow inbound HTTPS traffic to Bastion'
        }
      }

      {
        name: 'AllowGatewayManagerIn'
        properties: {
          direction: 'Inbound'
          protocol: 'Tcp'
          access: 'Allow'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          sourcePortRange: '*'
          priority: 130
          description: 'Allow inbound HTTPS traffic to Bastion'
        }
      }

      {
        name: 'AllowLoadBalancer'
        properties: {
          direction: 'Inbound'
          protocol: 'Tcp'
          access: 'Allow'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          sourcePortRange: '*'
          priority: 140
          description: 'Allow inbound HTTPS traffic to Bastion'
        }
      }

      {
        name: 'AllowBastionHostCommunication'
        properties: {
          direction: 'Inbound'
          protocol: 'Tcp'
          access: 'Allow'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          sourcePortRange: '*'
          priority: 150
          description: 'Allow inbound HTTPS traffic to Bastion'
        }
      }

      {
        name: 'AllowSSHRDPOut'
        properties: {
          direction: 'Outbound'
          protocol: '*'
          access: 'Allow'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '22'
            '3389'
          ]
          sourcePortRange: '*'
          priority: 100
          description: ''
        }
      }

      {
        name: 'AllowAzureCloudOut'
        properties: {
          direction: 'Outbound'
          protocol: 'Tcp'
          access: 'Allow'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureCloud'
          destinationPortRange: '443'
          sourcePortRange: '*'
          priority: 110
          description: ''
        }
      }

      {
        name: 'AllowBastionCommunication'
        properties: {
          direction: 'Outbound'
          protocol: '*'
          access: 'Allow'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          sourcePortRange: '*'
          priority: 120
          description: ''
        }
      }
      {
        name: 'AllowGetSessionInfo'
        properties: {
          direction: 'Outbound'
          protocol: '*'
          access: 'Allow'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRange: '80'
          sourcePortRange: '*'
          priority: 130
          description: ''
        }
      }
    ]
  }
}

resource private_dns_file_zone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.file.core.windows.net'
  location: 'global'
}

resource private_dns_sql_zone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.database.windows.net'
  location: 'global'
}

resource privateDnsZones_private_name_resource 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZones_private_name
  location: 'global'
}

resource virtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${private_dns_file_zone.name}/vnet-${projectName}${envSuffix}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: client_vnet.id
    }
  }
}

resource virtualNetworkSQLLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${private_dns_sql_zone.name}/vnet-${projectName}${envSuffix}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: client_vnet.id
    }
  }
}

resource privateDnsZones_private_name_vnet_prod 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privateDnsZones_private_name_resource.name}/vnet-${projectName}${envSuffix}'
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: client_vnet.id
    }
  }
}

resource privateDnsZones_private_name_vnet_hub_prod 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privateDnsZones_private_name_resource.name}/vnet-hub${envSuffix}'
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: hub_vnet.id
    }
  }
}

output client_vnet_id string = client_vnet.id
output hub_vnet_id string = hub_vnet.id
output private_dns_zone_name_id string = private_dns_file_zone.id
output private_dns_sql_zone_name_id string = private_dns_sql_zone.id
output private_dns_name_id string = privateDnsZones_private_name_resource.id
output clien_vnet_address_space string = client_vnet.properties.addressSpace.addressPrefixes[0]
