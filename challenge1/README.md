# Challenge 1

## Getting Started

Deploy the resource group:

```
az deployment sub create --location westeurope --template-file ./create-rg.json
```
Deploy all resources inside the resource group:

```
az deployment group create --resource-group rg-lab-challenge1 --template-file ./main.json
```
## Considerations

- The resource group creation is separated from the rest of the resources to simplify the submodules and manage subscription-level permissions.

- All resources are deployed in the same resource group. Therefore, "location": "[resourceGroup().location]" is used in all modules.

- VNet configuration: The VNet name is configurable and must be consistent across all parameter files:
```
"vnetName": { "value": "name-vnet" }
```
- UDR configuration: The UDR name is configurable in its own parameters file, but the VNet module (vnet.json) references it directly using resourceId(). Therefore, the following is hardcoded in
  vnet.json:
```
Copy code
"routeTable": {
    "id": "[resourceId('Microsoft.Network/routeTables', 'udr-lab-challenge1')]"
}
```
- Server IP: The server uses a static IP, which is required to create a NAT rule in the firewall.

- Firewall rules: Only one rule is configured to allow outbound traffic from the server to the internet. No inbound rules are added, as the default is to deny all inbound traffic. Additional rules will be added in Challenge 2.

- User and password of the server is written in the params file, that is a bad practise, It should be read from a keyvault.  
