# Azure Endpoint Discovery Report

## Overview
- Report Generated: 2025-04-23 21:22:07
- Total Subscriptions Assessed: 1
- Total Resources Identified: 14
- Total Endpoints Discovered: 32

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


