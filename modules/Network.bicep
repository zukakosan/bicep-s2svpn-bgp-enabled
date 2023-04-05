param location string
param nsgId string
param vpngwName string
param vnetAddressPrefix string
param subnet1AddressPrefix string
param gatewaySubnetAddressPrefix string
param asn int
param vmName string

// VNETの作成
resource vpnVNet 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'vpn-cloud-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        // '10.0.0.0/16'
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          // addressPrefix: '10.0.0.0/24'
          addressPrefix: gatewaySubnetAddressPrefix
        }
      }
      {
        name: 'Subnet-1'
        properties: {
          // addressPrefix: '10.0.1.0/24'
          addressPrefix: subnet1AddressPrefix
          networkSecurityGroup: {
            id: nsgId
          }
        }
      }
    ]
  }
  //後でサブネットのidを再利用できるように名前を付ける
  resource VNetGatewaySubnet 'subnets' existing = {
    name: 'GatewaySubnet'
  }
  resource VNetSubnet1 'subnets' existing = {
    name: 'Subnet-1'
  }
}

// GW用パブリックIPの作成
resource vpngwPublicIP 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: 'pip-${vpngwName}'
  // name: 'sample-gw-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// VPN GWの作成
resource vpngw 'Microsoft.Network/virtualNetworkGateways@2020-11-01' = {
  name: 'gw-${vpngwName}'
  location: location
  properties: {
    bgpSettings: {
      // asn: 65010
      asn: asn
    }
    ipConfigurations: [
      {
        name: 'gw-ipconfig-${vpngwName}'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vpnVNet::VNetGatewaySubnet.id
          }
          publicIPAddress: {
            id: vpngwPublicIP.id
          }
        }
      }
    ]
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: true
  }
}

//クラウド側VPNGatewayのlocal network gateway
resource vpngwLNG 'Microsoft.Network/localNetworkGateways@2019-11-01' = {
  name: 'lng-${vpngwName}'
  location: location
  properties: {
    bgpSettings:{
      asn: asn
      bgpPeeringAddress: vpngw.properties.bgpSettings.bgpPeeringAddress
    }
    // localNetworkAddressSpace: {
    //   addressPrefixes: [
    //     'REQUIRED'
    //   ]
    // }
    gatewayIpAddress: vpngwPublicIP.properties.ipAddress
  }
}

// クラウドおよびオンプレVNETにVM作成
resource vmNic 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'nic-${vmName}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vpnVNet::VNetSubnet1.id
          }
        }
      }
    ]
  }
}

resource ubuntuVM 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'vm-${vmName}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_A2_v2'
    }
    osProfile: {
      computerName: 'cloudubuntu'
      adminUsername: 'AzureAdmin'
      adminPassword: 'P@ssw0rd#20230405'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '16.04-LTS'
        version: 'latest'
      }
      osDisk: {
        name: 'cloudUbuntu-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNic.id
        }
      ]
    }
    // diagnosticsProfile: {
    //   bootDiagnostics: {
    //     enabled: true
    //     storageUri: 'storageUri'
    //   }
    // }
  }
}
