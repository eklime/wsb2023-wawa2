var location = resourceGroup().location
param envSuffix string
param availabilitysetname string

resource AvailabilitySet 'Microsoft.Compute/availabilitySets@2021-04-01' = {
  name: '${availabilitysetname}${envSuffix}'
  location: location
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 5
  }
  sku: {
    name: 'Aligned'
  }
}

output availabilitySetID string = AvailabilitySet.id
