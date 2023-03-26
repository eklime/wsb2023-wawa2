param ilbname string
param envSuffix string
param location string = resourceGroup().location
param sku_name string = 'Standard'
param sku_tier string = 'Regional'
param subnet_ID string

var ilbname_env = '${ilbname}${envSuffix}'

resource ilb 'Microsoft.Network/loadBalancers@2021-02-01' = {
  name: ilbname_env
  location: location
  properties: {
    backendAddressPools: [
      {
        name: 'BackendPool'
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontend'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddressVersion: 'IPv4'
          subnet: {
            id: subnet_ID
          }
        }
      }
    ]
    loadBalancingRules: [
      {
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', ilbname_env, 'LoadBalancerFrontend')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', ilbname_env, 'BackendPool')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', ilbname_env, 'lbprobe')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          idleTimeoutInMinutes: 15
        }
        name: 'lbrule'
      }
    ]
    probes: [
      {
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 15
          numberOfProbes: 2
        }
        name: 'lbprobe'
      }
    ]
  }
  sku: {
    name: sku_name
    tier: sku_tier
  }
}
output ilb_backend_pool string = ilb.properties.backendAddressPools[0].id
output ilb_probe string = ilb.properties.probes[0].id
output ilb_ip string = ilb.properties.frontendIPConfigurations[0].properties.privateIPAddress
output ilb_name string = ilb.name
