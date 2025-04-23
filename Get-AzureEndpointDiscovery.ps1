<#
.SYNOPSIS
    Discovers Azure resources with externally accessible endpoints across multiple subscriptions.

.DESCRIPTION
    This script connects to multiple Azure subscriptions/tenants and identifies any configured 
    resources hosting endpoints accessible from the internet. It generates a detailed report 
    in Markdown format, listing the resource details, endpoint IP/FQDN, and the associated subscription.

.PARAMETER SubscriptionIds
    Optional. Array of subscription IDs to assess. If not provided, all accessible subscriptions will be assessed.

.PARAMETER OutputPath
    Optional. Path where the report will be saved. Default is the current directory.

.PARAMETER SkipResourceTypes
    Optional. Array of resource types to skip during assessment.

.PARAMETER TenantId
    Optional. Tenant ID to use when connecting to Azure.

.EXAMPLE
    .\Get-AzureEndpointDiscovery.ps1
    Runs the script against all accessible subscriptions and saves the report in the current directory.

.EXAMPLE
    .\Get-AzureEndpointDiscovery.ps1 -SubscriptionIds @("00000000-0000-0000-0000-000000000000") -OutputPath "C:\Reports"
    Runs the script against the specified subscription and saves the report in the specified directory.

.EXAMPLE
    .\Get-AzureEndpointDiscovery.ps1 -SkipResourceTypes @("VirtualMachines", "WebApps")
    Runs the script against all accessible subscriptions, skipping Virtual Machines and Web Apps.

.NOTES
    Author: liarm
    Date: April 20, 2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string[]]$SubscriptionIds,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Get-Location).Path,
    
    [Parameter(Mandatory = $false)]
    [string[]]$SkipResourceTypes,
    
    [Parameter(Mandatory = $false)]
    [string]$TenantId
)

#region Script Initialization
# Script Variables
$script:ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "Modules"
$script:ReportDate = Get-Date -Format "yyyy-MM-dd_HH-mm-ss-fff"
$script:ReportsBaseFolder = Join-Path -Path $PSScriptRoot -ChildPath "Reports"
# The actual report paths will be set during subscription processing
$script:ResourceTypes = @(
    "VirtualMachines",
    "PublicIPAddresses",
    "WebApps",
    "AKS",
    "ApplicationGateways",
    "LoadBalancers",
    "SQLDatabases",
    "SQLManagedInstances",
    "StorageAccounts",
    "AppServices",
    "TrafficManagerProfiles",
    "APIManagementServices",
    "CDNEndpoints",
    "RedisCache",
    "CosmosDB",
    "ServiceBus",
    "EventHubs",
    "ExpressRouteCircuits",
    "VPNGateways",
    "DNSZones",
    "AzureFirewall",
    "AzureFrontDoor",
    "AzureBastion",
    "SignalRService",
    "SpringApps",
    "EventGrid",
    "IoTHub",
    "AzureSphere",
    "ApplicationInsights",
    "DigitalTwins",
    "SynapseAnalytics",
    "DataExplorer",
    "StaticWebApps",
    "Batch",
    "DedicatedHosts"
)

# Remove skipped resource types
if ($SkipResourceTypes) {
    $script:ResourceTypes = $script:ResourceTypes | Where-Object { $_ -notin $SkipResourceTypes }
}

# Results container
$script:Results = @{}
$script:TotalResources = 0
$script:TotalEndpoints = 0
#endregion

#region Functions
function Test-AzureModules {
    [CmdletBinding()]
    param()
    
    $requiredModules = @("Az.Accounts", "Az.Resources")
    $missingModules = @()
    
    foreach ($module in $requiredModules) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            $missingModules += $module
        }
    }
    
    if ($missingModules.Count -gt 0) {
        Write-Warning "The following required modules are missing: $($missingModules -join ', ')"
        $installModules = Read-Host "Do you want to install the missing modules? (Y/N)"
        
        if ($installModules -eq "Y" -or $installModules -eq "y") {
            foreach ($module in $missingModules) {
                try {
                    Write-Host "Installing module $module..."
                    Install-Module -Name $module -Scope CurrentUser -Force
                }
                catch {
                    Write-Error "Failed to install module $module. Error: $_"
                    return $false
                }
            }
        }
        else {
            Write-Error "Required modules are missing. Please install them manually."
            return $false
        }
    }
    
    return $true
}

function Connect-AzureSubscriptions {
    [CmdletBinding()]
    param()
    
    try {
        # If SubscriptionIds are provided, do not prompt or connect interactively
        if ($SubscriptionIds) {
            $subscriptions = @()
            foreach ($subId in $SubscriptionIds) {
                $subObj = Get-AzSubscription -SubscriptionId $subId -ErrorAction SilentlyContinue
                if ($subObj) { $subscriptions += $subObj }
                else { Write-Warning "Subscription $subId not found or not accessible." }
            }
        }
        else {
            # Check if already connected
            $context = Get-AzContext
            if (-not $context) {
                Write-Host "No Azure session found. Please authenticate with Connect-AzAccount before running this script."
                return $null
            }
            $subscriptions = Get-AzSubscription
        }
        
        if (-not $subscriptions -or $subscriptions.Count -eq 0) {
            Write-Error "No subscriptions found or accessible."
            return $null
        }
        
        return $subscriptions
    }
    catch {
        Write-Error "Failed to connect to Azure. Error: $_"
        return $null
    }
}

function Import-AssessmentModules {
    [CmdletBinding()]
    param()
    
    if (-not (Test-Path -Path $script:ModulePath)) {
        Write-Warning "Modules directory not found. Creating directory..."
        New-Item -Path $script:ModulePath -ItemType Directory -Force | Out-Null
    }
    
    $moduleFiles = Get-ChildItem -Path $script:ModulePath -Filter "*.psm1" -ErrorAction SilentlyContinue
    
    if (-not $moduleFiles -or $moduleFiles.Count -eq 0) {
        Write-Warning "No assessment modules found in $($script:ModulePath). Using built-in functions."
        return $false
    }
    
    foreach ($moduleFile in $moduleFiles) {
        try {
            Import-Module $moduleFile.FullName -Force
            Write-Verbose "Imported module: $($moduleFile.Name)"
        }
        catch {
            Write-Error "Failed to import module $($moduleFile.Name). Error: $_"
        }
    }
    
    return $true
}

function Get-ResourceEndpoints {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,
        
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionName,
        
        [Parameter(Mandatory = $true)]
        [string]$ResourceType
    )
    
    try {
        # Set subscription context
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
        
        # Check if there's a specialized function for this resource type
        $functionName = "Get-${ResourceType}Endpoints"
        if (Get-Command $functionName -ErrorAction SilentlyContinue) {
            Write-Verbose "Using specialized function for $ResourceType`: $($functionName -replace ':', '\:')"
            $endpoints = & $functionName
        }
        else {
            # Use the built-in generic function
            Write-Verbose "Using built-in function for $ResourceType"
            $endpoints = Get-GenericResourceEndpoints -ResourceType $ResourceType
        }
        
        return $endpoints
    }
    catch {
        Write-Error "Error assessing $ResourceType in subscription $SubscriptionName. Error: $_"
        return @()
    }
}

function Get-GenericResourceEndpoints {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceType
    )
    
    $findings = @()
    
    # Map script resource type to Azure resource type
    $azureResourceType = switch ($ResourceType) {
        "VirtualMachines" { "Microsoft.Compute/virtualMachines" }
        "PublicIPAddresses" { "Microsoft.Network/publicIPAddresses" }
        "WebApps" { "Microsoft.Web/sites" }
        "AKS" { "Microsoft.ContainerService/managedClusters" }
        "ApplicationGateways" { "Microsoft.Network/applicationGateways" }
        "LoadBalancers" { "Microsoft.Network/loadBalancers" }
        "SQLDatabases" { "Microsoft.Sql/servers/databases" }
        "SQLManagedInstances" { "Microsoft.Sql/managedInstances" }
        "StorageAccounts" { "Microsoft.Storage/storageAccounts" }
        "AppServices" { "Microsoft.Web/sites" }
        "TrafficManagerProfiles" { "Microsoft.Network/trafficManagerProfiles" }
        "APIManagementServices" { "Microsoft.ApiManagement/service" }
        "CDNEndpoints" { "Microsoft.Cdn/profiles/endpoints" }
        "RedisCache" { "Microsoft.Cache/Redis" }
        "CosmosDB" { "Microsoft.DocumentDB/databaseAccounts" }
        "ServiceBus" { "Microsoft.ServiceBus/namespaces" }
        "EventHubs" { "Microsoft.EventHub/namespaces" }
        "ExpressRouteCircuits" { "Microsoft.Network/expressRouteCircuits" }
        "VPNGateways" { "Microsoft.Network/virtualNetworkGateways" }
        "DNSZones" { "Microsoft.Network/dnszones" }
        "AzureFirewall" { "Microsoft.Network/azureFirewalls" }
        "AzureFrontDoor" { "Microsoft.Network/frontDoors" }
        "AzureBastion" { "Microsoft.Network/bastionHosts" }
        "SignalRService" { "Microsoft.SignalRService/SignalR" }
        "SpringApps" { "Microsoft.AppPlatform/Spring" }
        "EventGrid" { "Microsoft.EventGrid/domains" }
        "IoTHub" { "Microsoft.Devices/IotHubs" }
        "AzureSphere" { "Microsoft.AzureSphere/catalogs" }
        "ApplicationInsights" { "Microsoft.Insights/components" }
        "DigitalTwins" { "Microsoft.DigitalTwins/digitalTwinsInstances" }
        "SynapseAnalytics" { "Microsoft.Synapse/workspaces" }
        "DataExplorer" { "Microsoft.Kusto/clusters" }
        "StaticWebApps" { "Microsoft.Web/staticSites" }
        "Batch" { "Microsoft.Batch/batchAccounts" }
        "DedicatedHosts" { "Microsoft.Compute/hostGroups" }
        default { $null }
    }
    
    if (-not $azureResourceType) {
        Write-Warning "No Azure resource type mapping found for $ResourceType"
        return $findings
    }
    
    # Get resources of the specified type
    $resources = Get-AzResource -ResourceType $azureResourceType
    
    foreach ($resource in $resources) {
        $resourceGroup = $resource.ResourceGroupName
        $resourceName = $resource.Name
        
        # This is a generic function, so we can only make basic assumptions about endpoints
        # Specialized functions should be created for each resource type for better accuracy
        
        # Try to find any public endpoints based on resource type
        switch ($ResourceType) {
            "PublicIPAddresses" {
                $ipResource = Get-AzPublicIpAddress -Name $resourceName -ResourceGroupName $resourceGroup
                if ($ipResource -and $ipResource.IpAddress -ne "Dynamic" -and $ipResource.IpAddress -ne $null) {
                    $findings += [PSCustomObject]@{
                        ResourceGroup = $resourceGroup
                        ResourceName = $resourceName
                        Endpoint = $ipResource.IpAddress
                        Type = "Public IP"
                    }
                }
            }
            "WebApps" {
                $webApp = Get-AzWebApp -Name $resourceName -ResourceGroupName $resourceGroup
                if ($webApp) {
                    $findings += [PSCustomObject]@{
                        ResourceGroup = $resourceGroup
                        ResourceName = $resourceName
                        Endpoint = $webApp.DefaultHostName
                        Type = "FQDN"
                    }
                }
            }
            "StorageAccounts" {
                $storageAccount = Get-AzStorageAccount -Name $resourceName -ResourceGroupName $resourceGroup
                if ($storageAccount) {
                    # Check if public blob access is enabled
                    if ($storageAccount.AllowBlobPublicAccess -eq $true) {
                        $findings += [PSCustomObject]@{
                            ResourceGroup = $resourceGroup
                            ResourceName = $resourceName
                            Endpoint = "$($resourceName).blob.core.windows.net"
                            Type = "FQDN"
                        }
                    }
                }
            }
            "CosmosDB" {
                try {
                    # Get CosmosDB account without prompting for input
                    $cosmosDbAccount = Get-AzResource -ResourceType "Microsoft.DocumentDB/databaseAccounts" -ResourceGroupName $resourceGroup -Name $resourceName -ErrorAction Stop
                    if ($cosmosDbAccount) {
                        # For CosmosDB, we can construct the endpoint URL based on the account name
                        $findings += [PSCustomObject]@{
                            ResourceGroup = $resourceGroup
                            ResourceName = $resourceName
                            Endpoint = "$($resourceName).documents.azure.com"
                            Type = "FQDN"
                        }
                    }
                }
                catch {
                    Write-Verbose "Error getting CosmosDB account $resourceName in resource group $resourceGroup. Error: $_"
                }
            }
            default {
                # For other resource types, we'll need specialized functions
                # This is just a placeholder for generic resources
                Write-Verbose "No specialized endpoint detection for $ResourceType. Consider creating a dedicated function."
            }
        }
    }
    
    return $findings
}

function Export-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Results,
        
        [Parameter(Mandatory = $true)]
        [string]$ReportFile,
        
        [Parameter(Mandatory = $true)]
        [int]$TotalSubscriptions,
        
        [Parameter(Mandatory = $true)]
        [int]$TotalResources,
        
        [Parameter(Mandatory = $true)]
        [int]$TotalEndpoints
    )
    
    try {
        $reportContent = @"
# Azure Endpoint Discovery Report

## Overview
- Report Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- Total Subscriptions Assessed: $TotalSubscriptions
- Total Resources Identified: $TotalResources
- Total Endpoints Discovered: $TotalEndpoints

"@
        
        foreach ($subscription in $Results.Keys) {
            $subscriptionData = $Results[$subscription]
            $subscriptionId = $subscriptionData.SubscriptionId
            $subscriptionName = $subscriptionData.SubscriptionName
            
            $reportContent += @"

## Subscription: $subscriptionName
- Subscription ID: $subscriptionId

"@
            
            $resourceGroups = $subscriptionData.Endpoints | Group-Object -Property ResourceGroup
            
            foreach ($resourceGroup in $resourceGroups) {
                $reportContent += @"

### Resource Group: $($resourceGroup.Name)

"@
                
                $resourceTypes = $resourceGroup.Group | Group-Object -Property ResourceType
                
                foreach ($resourceType in $resourceTypes) {
                    $reportContent += @"

#### Resource Type: $($resourceType.Name)

| Resource Name | Endpoint | Type |
|---------------|----------|------|

"@
                    
                    foreach ($endpoint in $resourceType.Group) {
                        $reportContent += "| $($endpoint.ResourceName) | $($endpoint.Endpoint) | $($endpoint.Type) |`n"
                    }
                }
            }
        }
        
        # Write report to file
        $reportContent | Out-File -FilePath $ReportFile -Encoding utf8
        
        Write-Host "Report generated successfully: $ReportFile"
        return $true
    }
    catch {
        Write-Error "Failed to generate report. Error: $_"
        return $false
    }
}

function Export-CsvReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Results,
        
        [Parameter(Mandatory = $true)]
        [string]$CsvFile
    )
    
    try {
        $csvData = @()
        
        foreach ($subscription in $Results.Keys) {
            $subscriptionData = $Results[$subscription]
            $subscriptionId = $subscriptionData.SubscriptionId
            $subscriptionName = $subscriptionData.SubscriptionName
            
            foreach ($endpoint in $subscriptionData.Endpoints) {
                $csvData += [PSCustomObject]@{
                    SubscriptionId = $subscriptionId
                    SubscriptionName = $subscriptionName
                    ResourceGroup = $endpoint.ResourceGroup
                    ResourceType = $endpoint.ResourceType
                    ResourceName = $endpoint.ResourceName
                    Endpoint = $endpoint.Endpoint
                    EndpointType = $endpoint.Type
                }
            }
        }
        
        # Export to CSV
        $csvData | Export-Csv -Path $CsvFile -NoTypeInformation -Encoding UTF8
        
        Write-Host "CSV report generated successfully: $CsvFile"
        return $true
    }
    catch {
        Write-Error "Failed to generate CSV report. Error: $_"
        return $false
    }
}
#endregion

#region Main Script Execution
# Check for required modules
if (-not (Test-AzureModules)) {
    Write-Error "Required modules are missing. Please install them and try again."
    exit 1
}

# Ensure user is authenticated before running (fail fast if not)
$context = Get-AzContext
if (-not $context) {
    Write-Error "No Azure session found. Please authenticate with Connect-AzAccount before running this script."
    exit 1
}

# Connect to Azure (removed Connect-AzAccount calls)
$subscriptions = Connect-AzureSubscriptions
if (-not $subscriptions) {
    Write-Error "Failed to connect to Azure subscriptions. Exiting."
    exit 1
}

# Import assessment modules
Import-AssessmentModules

# Create base reports folder if it doesn't exist
if (-not (Test-Path -Path $script:ReportsBaseFolder)) {
    New-Item -Path $script:ReportsBaseFolder -ItemType Directory -Force | Out-Null
}

# Process each subscription
foreach ($subscription in $subscriptions) {
    $subscriptionId = $subscription.Id
    $subscriptionName = $subscription.Name
    
    Write-Host "Processing subscription: $subscriptionName ($subscriptionId)"
    
    # Explicitly set the context to the correct tenant and subscription (if TenantId is provided)
    if ($PSBoundParameters.ContainsKey('TenantId') -and $TenantId) {
        Write-Host "Setting context to Tenant: $TenantId, Subscription: $subscriptionId"
        $context = Set-AzContext -TenantId $TenantId -SubscriptionId $subscriptionId
    } else {
        Write-Host "Setting context to Subscription: $subscriptionId (no TenantId provided)"
        $context = Set-AzContext -SubscriptionId $subscriptionId
    }
    
    # Get tenant details
    $tenantId = $context.Tenant.Id
    $tenantName = (Get-AzTenant -TenantId $tenantId).Name
    if (-not $tenantName) {
        $tenantName = "Tenant-$tenantId"
    }
    
    # Create folder structure: Reports/TenantName/SubscriptionName/
    $tenantFolder = Join-Path -Path $script:ReportsBaseFolder -ChildPath $tenantName
    if (-not (Test-Path -Path $tenantFolder)) {
        New-Item -Path $tenantFolder -ItemType Directory -Force | Out-Null
    }
    
    $subscriptionFolder = Join-Path -Path $tenantFolder -ChildPath $subscriptionName
    if (-not (Test-Path -Path $subscriptionFolder)) {
        New-Item -Path $subscriptionFolder -ItemType Directory -Force | Out-Null
    }
    
    # Set report paths for this subscription
    $script:ReportFile = Join-Path -Path $subscriptionFolder -ChildPath "AzureEndpointDiscovery_$($script:ReportDate).md"
    $script:CsvReportFile = Join-Path -Path $subscriptionFolder -ChildPath "AzureEndpointDiscovery_$($script:ReportDate).csv"
    
    # Initialize results for this subscription
    $script:Results[$subscriptionId] = @{
        SubscriptionId = $subscriptionId
        SubscriptionName = $subscriptionName
        TenantId = $tenantId
        TenantName = $tenantName
        Endpoints = @()
    }
    
    # Process each resource type
    foreach ($resourceType in $script:ResourceTypes) {
        Write-Host "  Assessing $resourceType..."
        
        $endpoints = Get-ResourceEndpoints -SubscriptionId $subscriptionId -SubscriptionName $subscriptionName -ResourceType $resourceType
        
        if ($endpoints -and $endpoints.Count -gt 0) {
            # Add resource type to each endpoint
            $endpoints | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name "ResourceType" -Value $resourceType -Force
            }
            
            $script:Results[$subscriptionId].Endpoints += $endpoints
            $script:TotalResources += ($endpoints | Select-Object -Property ResourceName -Unique).Count
            $script:TotalEndpoints += $endpoints.Count
            
            Write-Host "    Found $($endpoints.Count) endpoints."
        }
        else {
            Write-Host "    No endpoints found."
        }
    }
    
    # Generate individual subscription reports
    if ($script:Results[$subscriptionId].Endpoints.Count -gt 0) {
        $subResults = @{ $subscriptionId = $script:Results[$subscriptionId] }
        Export-MarkdownReport -Results $subResults -ReportFile $script:ReportFile -TotalSubscriptions 1 -TotalResources ($subResults[$subscriptionId].Endpoints | Select-Object -Property ResourceName -Unique).Count -TotalEndpoints $subResults[$subscriptionId].Endpoints.Count
        Export-CsvReport -Results $subResults -CsvFile $script:CsvReportFile
        
        Write-Host "  Generated subscription-specific reports in: $subscriptionFolder"
    } else {
        Write-Host "  No results found for subscription. No report generated."
    }
}

# Generate consolidated reports in the base Reports folder
if ($script:Results.Keys.Count -gt 0) {
    $consolidatedReportFile = Join-Path -Path $script:ReportsBaseFolder -ChildPath "ConsolidatedAzureEndpointDiscovery_$($script:ReportDate).md"
    $consolidatedCsvReportFile = Join-Path -Path $script:ReportsBaseFolder -ChildPath "ConsolidatedAzureEndpointDiscovery_$($script:ReportDate).csv"
    
    Export-MarkdownReport -Results $script:Results -ReportFile $consolidatedReportFile -TotalSubscriptions $subscriptions.Count -TotalResources $script:TotalResources -TotalEndpoints $script:TotalEndpoints
    Export-CsvReport -Results $script:Results -CsvFile $consolidatedCsvReportFile
    
    Write-Host "Consolidated reports generated in: $script:ReportsBaseFolder"
} else {
    Write-Warning "No results found across any subscriptions. No consolidated reports generated."
}

Write-Host "Script completed successfully."
#endregion
