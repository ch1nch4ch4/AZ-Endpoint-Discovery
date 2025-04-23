## Azure Endpoint Discovery Script

### Overview
The `Get-AzureEndpointDiscovery.ps1` script is a PowerShell tool designed to connect to multiple Azure subscriptions/tenants and identify resources that host endpoints accessible from the internet. The script outputs a detailed report in both Markdown and CSV formats, listing the resource details, endpoint IP/FQDN, and the associated subscription. This helps in understanding the exposure of resources to external access.

### Features
- **Modular Design**: Specialized functions for each resource type.
- **Dynamic Module Loading**: Automatically detects and installs required Azure PowerShell modules.
- **Resource Discovery**: Identifies externally accessible endpoints for various Azure resources.
- **Detailed Reporting**: Generates both Markdown and CSV formatted reports with resource details and endpoints.
- **Subscription Iteration**: Processes multiple subscriptions to compile a comprehensive report.

### Parameters
- **SubscriptionIds**: Optional array of subscription IDs to assess. If not provided, all accessible subscriptions will be assessed.
- **OutputPath**: Optional path where the report will be saved. Default is the current directory.
- **SkipResourceTypes**: Optional array of resource types to skip during assessment.
- **TenantId**: Optional tenant ID to use when connecting to Azure.

### Supported Azure Resources
The script focuses on the following Azure resources that could potentially have externally facing entry points:
- Virtual Machines
- Public IP Addresses
- Web Apps
- Azure Kubernetes Service (AKS)
- Application Gateways
- Load Balancers
- Azure SQL Databases
- Azure SQL Managed Instances
- Storage Accounts
- App Services (Azure Functions, Logic Apps)
- Traffic Manager Profiles
- API Management Services
- CDN Endpoints
- Redis Cache
- Cosmos DB
- Service Bus
- Event Hubs
- ExpressRoute Circuits
- VPN Gateways
- DNS Zones
- Azure Firewall
- Azure Front Door
- Azure Bastion
- Azure SignalR Service
- Azure Spring Apps
- Event Grid
- Azure IoT Hub
- Azure Sphere
- Application Insights
- Azure Digital Twins
- Azure Synapse Analytics
- Azure Data Explorer (Kusto)
- Azure Static Web Apps
- Azure Batch
- Azure Dedicated Hosts

### Module Structure
The script uses a modular approach with specialized modules for different resource types:

- **VirtualMachines.psm1**
  - Virtual Machines

- **WebApps.psm1**
  - Web Apps
  - App Services (Azure Functions, Logic Apps)

- **StorageAccounts.psm1**
  - Storage Accounts

- **SQLDatabases.psm1**
  - Azure SQL Databases
  - Azure SQL Managed Instances

- **AKS.psm1**
  - Azure Kubernetes Service (AKS)

- **NetworkResources.psm1**
  - Application Gateways
  - Load Balancers
  - Traffic Manager Profiles
  - Public IP Addresses

- **APIManagement.psm1**
  - API Management Services

- **FrontDoor.psm1**
  - Azure Front Door

- **CDNEndpoints.psm1**
  - CDN Endpoints

- **DatabaseServices.psm1**
  - Redis Cache
  - Cosmos DB

- **MessagingServices.psm1**
  - Service Bus
  - Event Hubs
  - Event Grid

- **IoTServices.psm1**
  - Azure IoT Hub
  - Azure Sphere
  - Azure Digital Twins

- **NetworkConnectivity.psm1**
  - DNS Zones
  - VPN Gateways
  - ExpressRoute Circuits

- **SecurityServices.psm1**
  - Azure Firewall
  - Azure Bastion
  - Azure SignalR Service

- **AnalyticsServices.psm1**
  - Application Insights
  - Azure Synapse Analytics
  - Azure Data Explorer (Kusto)

- **WebServices.psm1**
  - Azure Static Web Apps
  - Azure Spring Apps
  - Azure Batch
  - Azure Dedicated Hosts

- **DevOpsServices.psm1**
  - Azure DevOps Organizations and Projects

### Usage

```powershell
# Run against all accessible subscriptions
.\Get-AzureEndpointDiscovery.ps1

# Run against specific subscriptions
.\Get-AzureEndpointDiscovery.ps1 -SubscriptionIds @("00000000-0000-0000-0000-000000000000", "11111111-1111-1111-1111-111111111111")

# Specify output path
.\Get-AzureEndpointDiscovery.ps1 -OutputPath "C:\Reports"

# Skip specific resource types
.\Get-AzureEndpointDiscovery.ps1 -SkipResourceTypes @("VirtualMachines", "WebApps")

# Specify tenant ID
.\Get-AzureEndpointDiscovery.ps1 -TenantId "00000000-0000-0000-0000-000000000000"
```

### Example Output

```markdown
# Azure Endpoint Discovery Report

## Overview
- Report Generated: 2025-04-23 16:45:30
- Total Subscriptions Assessed: 3
- Total Resources Identified: 120
- Total Endpoints Discovered: 156

## Subscription: SubscriptionName1
- Subscription ID: 00000000-0000-0000-0000-000000000000

### Resource Group: ResourceGroupName1

#### Resource Type: Virtual Machines

| Resource Name | Endpoint | Type |
|---------------|----------|------|
| vm1           | 52.174.x.x | Public IP |
| vm2           | 52.174.x.x | Public IP |

### Resource Type: Web Apps

| Resource Name | Endpoint | Type |
|---------------|----------|------|
| webapp1       | webapp1.azurewebsites.net | FQDN |
| webapp2       | webapp2.azurewebsites.net | FQDN |

## Subscription: SubscriptionName2
- Subscription ID: 11111111-1111-1111-1111-111111111111

### Resource Group: ResourceGroupName2
#### Resource Type: Application Gateways

| Resource Name | Endpoint | Type |
|---------------|----------|------|
| appgw1        | 13.90.x.x | Public IP |
| appgw2        | 13.90.x.x | Public IP |
```

A CSV report is also generated with the same information in a tabular format for easier data analysis.

### Extending the Script
To add support for additional resource types:

1. Create a new module file in the `Modules` directory (e.g., `NewResourceType.psm1`)
2. Implement a function named `Get-NewResourceTypeEndpoints` that returns findings in the standard format
3. Export the function using `Export-ModuleMember`

The script will automatically detect and use the new module.

### Access Requirements
To run the script effectively, users need appropriate permissions in Azure. The script performs read operations across multiple resource types, requiring specific RBAC (Role-Based Access Control) roles.

#### Minimum Required Permissions
- **Reader Role**: Required at the subscription level to discover and assess resources.
  - Azure built-in role: `Reader`
  - This allows viewing all resources but not making changes.

#### Recommended Role
- **Security Reader**: Provides read-only access to security-related services.
  - Azure built-in role: `Security Reader`
  - ID: `39bc4728-0917-49c7-9d2c-d95423bc2eb4`
