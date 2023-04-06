# bicep-s2svpn-bgp
This bicep file deploys resources for S2S VPN between VNets enabling BGP.

The architecture image is bellow:
![architecture](./img/architecture.png)

# How to use
Create `params.json` to deploy resources. Please refer [params-sample.json](./params-sample.json)

Next create the resource group for this depoloyment.

```
$ az group create --name MyResourceGroup --location japaneast
```

Deploy main.bicep options:

- With parameter file

```
$ az deployment group create --resource-group MyResourceGroup --template-file main.bicep --parameters params.json
```

- Without parameter file

This option, you have to fill the parameters in the prompt.

```
$ az deployment group create --resource-group MyResourceGroup --template-file main.bicep

location: xxxx
vmAdminUserName: xxxx
vmAdminPassword: xxxx
principalId: xxxx
```

## For more information
Please refer this article.

https://zenn.dev/microsoft/articles/8d1558a8a2127c