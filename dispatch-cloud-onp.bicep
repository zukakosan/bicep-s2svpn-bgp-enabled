var location = 'japaneast'

module defaultNSG './modules/NSG.bicep' = {
  name: 'NetworkSecurityGroup'
  params:{
    location: location
    name: 'default-nsg'  
  }
}

module cloudInfra './modules/Network.bicep' = {
  name: 'cloudInfra'
  params: {
    location: location
    nsgId: defaultNSG.outputs.nsgId
    vpngwName: 'vpngwCloud'
    vnetAddressPrefix: '10.0.0.0/16'
    gatewaySubnetAddressPrefix: '10.0.0.0/24'
    subnet1AddressPrefix: '10.0.1.0/24'
    asn: 65010
    vmName: 'ubuntuCloud'
  }
}

// module onpInfra './modules/Network.bicep' = {
//   name: 'onpInfra'
//   params: {
//     location: location
//     nsgId: defaultNSG.outputs.nsgId
//     vpngwName: 'vpngwOnp'
//     vnetAddressPrefix: '
