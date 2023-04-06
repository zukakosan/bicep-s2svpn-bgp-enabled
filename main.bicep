param location string
param vmAdminUsername string
@secure()
param vmAdminPassword string
param principalId string

module defaultNSG './modules/NSG.bicep' = {
  name: 'NetworkSecurityGroup'
  params:{
    location: location
    name: 'nsg-default'  
  }
}

module cloudInfra './modules/main-resources.bicep' = {
  name: 'cloudInfra'
  params: {
    location: location
    nsgId: defaultNSG.outputs.nsgId
    vnetName: 'vnet-cloud'
    vpngwName: 'vpngw-cloud'
    vnetAddressPrefix: '10.0.0.0/16'
    gatewaySubnetAddressPrefix: '10.0.0.0/24'
    subnet1AddressPrefix: '10.0.1.0/24'
    asn: 65010
    vmName: 'ubuntu-cloud'
    vmAdminUsername: vmAdminUsername
    vmAdminPassword: vmAdminPassword
  }
}

module onpInfra './modules/main-resources.bicep' = {
  name: 'onpInfra'
  params: {
    location: location
    nsgId: defaultNSG.outputs.nsgId
    vnetName: 'vnet-onp'
    vpngwName: 'vpngw-onp'
    vnetAddressPrefix: '10.100.0.0/16'
    gatewaySubnetAddressPrefix: '10.100.0.0/24'
    subnet1AddressPrefix: '10.100.1.0/24'
    asn: 65020
    vmName: 'ubuntu-onp'
    vmAdminUsername: vmAdminUsername
    vmAdminPassword: vmAdminPassword
  }
}

// Connection from Cloud to Onp
resource conncetionCloudtoOnp 'Microsoft.Network/connections@2020-11-01' = {
  name: 'fromCloudtoOnp'
  location: location
  properties: {
    enableBgp: true
    virtualNetworkGateway1: {
      id: cloudInfra.outputs.vpngwId
      properties:{}
    }
    localNetworkGateway2: {
      id: onpInfra.outputs.lngId
      properties:{}
    }
    connectionType: 'IPsec'
    routingWeight: 0
    sharedKey: 'zukako'
  }
}

// Connection from Onp to Cloud
resource connectionOnptoCloud 'Microsoft.Network/connections@2020-11-01' = {
  name: 'fromOnptoCloud'
  location: location
  properties: {
    enableBgp: true
    virtualNetworkGateway1: {
      id: onpInfra.outputs.vpngwId
      properties:{}
    }
    localNetworkGateway2: {
      id: cloudInfra.outputs.lngId
      properties:{}
    }
    connectionType: 'IPsec'
    routingWeight: 0
    sharedKey: 'zukako'
  }
}

//contribution role to this resource group
module roleAssignment './modules/rbac-contribution.bicep' = {
  name: 'roleAssignment'
  params: {
    principalId: principalId
  }
  dependsOn: [
    cloudInfra
    onpInfra
  ]
}
