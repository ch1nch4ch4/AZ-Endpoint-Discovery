# Azure Endpoint Discovery Report

## Overview
- Report Generated: 2025-04-23 21:24:13
- Total Subscriptions Assessed: 10
- Total Resources Identified: 91
- Total Endpoints Discovered: 253

## Subscription: az-subscription-name
- Subscription ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

### Resource Group: example-resource-name

#### Resource Type: StaticWebApps

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | https://example.azurestaticapps.net | Static Web App Default Hostname |
| example-resource | example.company.com | Static Web App Custom Domain |
| example-resource/child-resource | https://.example.azurestaticapps.net | Static Web App Staging Environment |

## Subscription: az-subscription-name
- Subscription ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

## Subscription: az-subscription-name
- Subscription ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

### Resource Group: example-resource-name

#### Resource Type: PublicIPAddresses

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | 10.0.0.x | Public IP |
| example-resource | 10.0.0.x | Public IP |

#### Resource Type: WebApps

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | example.azurewebsites.net | Function App |
| example-resource | example.azurewebsites.net | Function App |
| example-resource | example.azurewebsites.net | Web App |
| example-resource | example.company.com | Web App Custom Domain |

#### Resource Type: SQLDatabases

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | example.database.windows.net | SQL Server (Restricted Access) |
| example-resource/child-resource | example.database.windows.net | SQL Database |

#### Resource Type: StorageAccounts

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | https://example.blob.core.windows.net/ | Blob Endpoint (Restricted Access) (Network: Allow All) |
| example-resource | https://example.file.core.windows.net/ | File Endpoint (Network: Allow All) |
| example-resource | https://example.table.core.windows.net/ | Table Endpoint (Network: Allow All) |
| example-resource | https://example.queue.core.windows.net/ | Queue Endpoint (Network: Allow All) |
| example-resource | https://example.web.core.windows.net/ | Static Website Endpoint (Network: Allow All) |
| example-resource | https://example.blob.core.windows.net/ | Blob Endpoint (Public Access) |
| example-resource | https://example.file.core.windows.net/ | File Endpoint |
| example-resource | https://example.table.core.windows.net/ | Table Endpoint |
| example-resource | https://example.queue.core.windows.net/ | Queue Endpoint |
| example-resource | https://example.web.core.windows.net/ | Static Website Endpoint |
| example-resource | https://example.blob.core.windows.net/ | Blob Endpoint (Public Access) |
| example-resource | https://example.file.core.windows.net/ | File Endpoint |
| example-resource | https://example.table.core.windows.net/ | Table Endpoint |
| example-resource | https://example.queue.core.windows.net/ | Queue Endpoint |
| example-resource | https://example.web.core.windows.net/ | Static Website Endpoint |

#### Resource Type: VPNGateways

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | 10.0.0.x | VPN Gateway (Public IP) |
| example-resource/child-resource | 10.0.0.x | VPN Gateway Public IP |

#### Resource Type: AzureFirewall

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | N/A | Azure Firewall |
| example-resource/child-resource | 10.0.0.x | Azure Firewall Public IP |

#### Resource Type: ApplicationInsights

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | Instrumentation Key Available | Application Insights Key |
| example-resource | Connection String Available | Application Insights Connection |
| example-resource | xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx | Application Insights ID |
| example-resource | example.applicationinsights.azure.com | Application Insights Ingestion Endpoint |
| example-resource | example.applicationinsights.azure.com | Application Insights Live Metrics Endpoint |

## Subscription: az-subscription-name
- Subscription ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

### Resource Group: example-resource-name

#### Resource Type: WebApps

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | example.azurewebsites.net | Web App |
| example-resource | test.t-example.com | Web App Custom Domain |
| example-resource | www.example.com | Web App Custom Domain |
| example-resource | example.com | Web App Custom Domain |
| example-resource | example.azurewebsites.net | Function App |

#### Resource Type: SQLDatabases

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | example.database.windows.net | SQL Server (Restricted Access) |
| example-resource | Azure Services | Allowed IP Range |
| example-resource | Azure Services | Allowed IP Range |
| example-resource | 10.0.0.x-10.0.0.x | Allowed IP Range |
| example-resource | 10.0.0.x-10.0.0.x | Allowed IP Range |
| example-resource | 10.0.0.x-10.0.0.x | Allowed IP Range |
| example-resource | 10.0.0.x-10.0.0.x | Allowed IP Range |
| example-resource | 10.0.0.x-10.0.0.x | Allowed IP Range |
| example-resource | 10.0.0.x-10.0.0.x | Allowed IP Range |
| example-resource | 10.0.0.x-10.0.0.x | Allowed IP Range |
| example-resource | 10.0.0.x-10.0.0.x | Allowed IP Range |
| example-resource/child-resource | example.database.windows.net | SQL Database |

#### Resource Type: StorageAccounts

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | https://example.blob.core.windows.net/ | Blob Endpoint (Restricted Access) (Network: Allow All) |
| example-resource | https://example.file.core.windows.net/ | File Endpoint (Network: Allow All) |
| example-resource | https://example.table.core.windows.net/ | Table Endpoint (Network: Allow All) |
| example-resource | https://example.queue.core.windows.net/ | Queue Endpoint (Network: Allow All) |
| example-resource | https://example.web.core.windows.net/ | Static Website Endpoint (Network: Allow All) |
| example-resource | https://example.blob.core.windows.net/ | Blob Endpoint (Public Access) (Network: Allow All) |
| example-resource | https://example.file.core.windows.net/ | File Endpoint (Network: Allow All) |
| example-resource | https://example.table.core.windows.net/ | Table Endpoint (Network: Allow All) |
| example-resource | https://example.queue.core.windows.net/ | Queue Endpoint (Network: Allow All) |
| example-resource | https://example.web.core.windows.net/ | Static Website Endpoint (Network: Allow All) |
| example-resource | https://example.blob.core.windows.net/ | Blob Endpoint (Public Access) (Network: Allow All) |
| example-resource | https://example.file.core.windows.net/ | File Endpoint (Network: Allow All) |
| example-resource | https://example.table.core.windows.net/ | Table Endpoint (Network: Allow All) |
| example-resource | https://example.queue.core.windows.net/ | Queue Endpoint (Network: Allow All) |
| example-resource | https://example.web.core.windows.net/ | Static Website Endpoint (Network: Allow All) |

#### Resource Type: VPNGateways

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | 10.0.0.x | VPN Gateway (Public IP) |
| example-resource/child-resource | 10.0.0.x | VPN Gateway Public IP |

#### Resource Type: ApplicationInsights

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | Instrumentation Key Available | Application Insights Key |
| example-resource | Connection String Available | Application Insights Connection |
| example-resource | xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx | Application Insights ID |
| example-resource | example.applicationinsights.azure.com | Application Insights Ingestion Endpoint |
| example-resource | example.applicationinsights.azure.com | Application Insights Live Metrics Endpoint |

### Resource Group: cloud-shell-storage-westeurope

#### Resource Type: StorageAccounts

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | https://example.blob.core.windows.net/ | Blob Endpoint (Restricted Access) (Network: Allow All) |
| example-resource | https://example.file.core.windows.net/ | File Endpoint (Network: Allow All) |
| example-resource | https://example.table.core.windows.net/ | Table Endpoint (Network: Allow All) |
| example-resource | https://example.queue.core.windows.net/ | Queue Endpoint (Network: Allow All) |
| example-resource | https://example.web.core.windows.net/ | Static Website Endpoint (Network: Allow All) |

## Subscription: az-subscription-name
- Subscription ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

### Resource Group: example

#### Resource Type: PublicIPAddresses

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | 10.0.0.x | Public IP |

#### Resource Type: StorageAccounts

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | https://example.blob.core.windows.net/ | Blob Endpoint (Public Access) |
| example-resource | https://example.file.core.windows.net/ | File Endpoint |
| example-resource | https://example.table.core.windows.net/ | Table Endpoint |
| example-resource | https://example.queue.core.windows.net/ | Queue Endpoint |
| example-resource | https://example.web.core.windows.net/ | Static Website Endpoint |

#### Resource Type: VPNGateways

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | 10.0.0.x | VPN Gateway (Public IP) |
| example-resource/child-resource | 10.0.0.x | VPN Gateway Public IP |

#### Resource Type: DNSZones

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | example.company.com | DNS Zone |

### Resource Group: example-prod-aks

#### Resource Type: PublicIPAddresses

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | 10.0.0.x | Public IP |
| example-resource | 10.0.0.x | Public IP |

#### Resource Type: LoadBalancers

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | N/A | Load Balancer |
| example-resource/child-resource | 10.0.0.x | Load Balancer Public IP |
| example-resource/child-resource | 10.0.0.x | Load Balancer Public IP |
| example-resource | N/A | Load Balancer |

#### Resource Type: StorageAccounts

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | https://example.blob.core.windows.net/ | Blob Endpoint (Restricted Access) (Network: Allow All) |
| example-resource | https://example.file.core.windows.net/ | File Endpoint (Network: Allow All) |
| example-resource | https://example.table.core.windows.net/ | Table Endpoint (Network: Allow All) |
| example-resource | https://example.queue.core.windows.net/ | Queue Endpoint (Network: Allow All) |
| example-resource | https://example.web.core.windows.net/ | Static Website Endpoint (Network: Allow All) |

### Resource Group: example-prod

#### Resource Type: AKS

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-aks-cluster | 10.0.0.x | AKS Load Balancer IP |
| example-aks-cluster | 10.0.0.x | AKS Load Balancer IP |

#### Resource Type: StorageAccounts

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | https://example.blob.core.windows.net/ | Blob Endpoint (Public Access) |
| example-resource | https://example.file.core.windows.net/ | File Endpoint |
| example-resource | https://example.table.core.windows.net/ | Table Endpoint |
| example-resource | https://example.queue.core.windows.net/ | Queue Endpoint |
| example-resource | https://example.web.core.windows.net/ | Static Website Endpoint |

### Resource Group: example-prod-monitoring

#### Resource Type: StorageAccounts

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | https://example.blob.core.windows.net/ | Blob Endpoint (Public Access) |
| example-resource | https://example.file.core.windows.net/ | File Endpoint |
| example-resource | https://example.table.core.windows.net/ | Table Endpoint |
| example-resource | https://example.queue.core.windows.net/ | Queue Endpoint |
| example-resource | https://example.web.core.windows.net/ | Static Website Endpoint |

#### Resource Type: DNSZones

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | example.company.com | DNS Zone |

### Resource Group: example-prod-prod01

#### Resource Type: StorageAccounts

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | https://example.blob.core.windows.net/ | Blob Endpoint (Public Access) |
| example-resource | https://example.file.core.windows.net/ | File Endpoint |
| example-resource | https://example.table.core.windows.net/ | Table Endpoint |
| example-resource | https://example.queue.core.windows.net/ | Queue Endpoint |
| example-resource | https://example.web.core.windows.net/ | Static Website Endpoint |

#### Resource Type: DNSZones

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | example.company.com | DNS Zone |

### Resource Group: terraform

#### Resource Type: StorageAccounts

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | https://example.blob.core.windows.net/ | Blob Endpoint (Restricted Access) (Network: Allow All) |
| example-resource | https://example.table.core.windows.net/ | Table Endpoint (Network: Allow All) |

### Resource Group: example-prod-servicebus

#### Resource Type: ServiceBus

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | example-prod-servicebus.servicebus.windows.net | Service Bus Namespace |
| example-resource | Public Access Enabled | Service Bus Network Access |

## Subscription: NC-UK CloudOps
- Subscription ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

### Resource Group: rg-example-01

#### Resource Type: WebApps

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | example.azurewebsites.net | Web App |
| example-resource | example.co.uk | Web App Custom Domain |

#### Resource Type: SQLDatabases

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | example.database.windows.net | SQL Server (Restricted Access) |
| example-resource | Azure Services | Allowed IP Range |
| example-resource | 10.0.0.x-10.0.0.x | Allowed IP Range |
| example-resource/child-resource | example.database.windows.net_db | SQL Database |

### Resource Group: rg-example-terraform

#### Resource Type: StorageAccounts

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | https://example.blob.core.windows.net/ | Blob Endpoint (Restricted Access) (Network: Allow All) |
| example-resource | https://example.file.core.windows.net/ | File Endpoint (Network: Allow All) |
| example-resource | https://example.table.core.windows.net/ | Table Endpoint (Network: Allow All) |
| example-resource | https://example.queue.core.windows.net/ | Queue Endpoint (Network: Allow All) |
| example-resource | https://example.web.core.windows.net/ | Static Website Endpoint (Network: Allow All) |
| example-resource | https://example.blob.core.windows.net/ | Blob Endpoint (Restricted Access) |
| example-resource | https://example.file.core.windows.net/ | File Endpoint |
| example-resource | https://example.table.core.windows.net/ | Table Endpoint |
| example-resource | https://example.queue.core.windows.net/ | Queue Endpoint |
| example-resource | https://example.web.core.windows.net/ | Static Website Endpoint |
| example-resource | https://example.blob.core.windows.net/ | Blob Endpoint (Restricted Access) (Network: Allow All) |
| example-resource | https://example.file.core.windows.net/ | File Endpoint (Network: Allow All) |
| example-resource | https://example.table.core.windows.net/ | Table Endpoint (Network: Allow All) |
| example-resource | https://example.queue.core.windows.net/ | Queue Endpoint (Network: Allow All) |
| example-resource | https://example.web.core.windows.net/ | Static Website Endpoint (Network: Allow All) |

### Resource Group: rg-example-monitoring

#### Resource Type: Batch

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-batch | https://example.uksouth.batch.azure.com | Batch Account Endpoint (Public Access) |
| example-resource | 10.0.0.x/0 | All IPs Allowed |

## Subscription: az-subscription-name
- Subscription ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

### Resource Group: example-front-01

#### Resource Type: PublicIPAddresses

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | 10.0.0.x | Public IP |
| example-resource | 10.0.0.x | Public IP |

#### Resource Type: ApplicationGateways

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | N/A | Application Gateway |
| example-resource/child-resource | 10.0.0.x | Application Gateway Public IP |
| example-resource/child-resource | xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.cloudapp.net | Application Gateway DNS |
| example-resource/child-resource | 80 | Application Gateway Port |

#### Resource Type: LoadBalancers

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | N/A | Load Balancer |
| example-resource/child-resource | 10.0.0.x | Load Balancer Public IP |

### Resource Group: op9-ddd-ODMD-hosts-01

#### Resource Type: PublicIPAddresses

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | 10.0.0.x | Public IP |

#### Resource Type: StorageAccounts

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | https://example.blob.core.windows.net/ | Blob Endpoint (Public Access) (Network: Allow All) |
| example-resource | https://example.file.core.windows.net/ | File Endpoint (Network: Allow All) |
| example-resource | https://example.table.core.windows.net/ | Table Endpoint (Network: Allow All) |
| example-resource | https://example.queue.core.windows.net/ | Queue Endpoint (Network: Allow All) |
| example-resource | https://example.web.core.windows.net/ | Static Website Endpoint (Network: Allow All) |
| example-resource | 10.0.0.x | Allowed IP Range |

#### Resource Type: AzureBastion

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | N/A | Azure Bastion |
| example-resource/child-resource | 10.0.0.x | Azure Bastion Public IP |

### Resource Group: example-resource-group-automation-tool

#### Resource Type: WebApps

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | example.azurewebsites.net | Function App |

#### Resource Type: StorageAccounts

| Resource Name | Endpoint | Type |
| example-resource | ---------- | ------ |
| example-resource | https://example.blob.core.windows.net/ | Blob Endpoint (Restricted Access) (Network: Allow All) |
| example-resource | https://example.file.core.windows.net/ | File Endpoint (Network: Allow All) |
| example-resource | https://example.table.core.windows.net/ | Table Endpoint (Network: Allow All) |
| example-resource | https://example.queue.core.windows.net/ | Queue Endpoint (Network: Allow All) |
| example-resource | 10.0.0.x | Allowed IP Range |
| example-resource | 10.0.0.x | Allowed IP Range |

