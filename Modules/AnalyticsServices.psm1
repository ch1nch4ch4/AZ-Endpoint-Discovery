<#
.SYNOPSIS
    Discovers analytics services with externally accessible endpoints.

.DESCRIPTION
    This module identifies Azure analytics services like Synapse Analytics,
    Data Explorer, and Application Insights and extracts their endpoint information.

.NOTES
    Author: liarm
    Date: April 20, 2025
#>

function Get-SynapseAnalyticsEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all Synapse workspaces in the current subscription
        $synapseWorkspaces = Get-AzSynapseWorkspace
        
        foreach ($workspace in $synapseWorkspaces) {
            $resourceGroup = $workspace.ResourceGroupName
            $resourceName = $workspace.Name
            
            Write-Verbose "Processing Synapse Workspace: $resourceName in $resourceGroup"
            
            # Get the connectivity endpoints
            $connectivityEndpoints = $workspace.ConnectivityEndpoints
            
            if ($connectivityEndpoints) {
                # SQL endpoint
                if ($connectivityEndpoints.sql) {
                    $findings += [PSCustomObject]@{
                        ResourceGroup = $resourceGroup
                        ResourceName = $resourceName
                        Endpoint = $connectivityEndpoints.sql
                        Type = "Synapse SQL Endpoint"
                    }
                }
                
                # SQL on-demand endpoint
                if ($connectivityEndpoints.sqlOnDemand) {
                    $findings += [PSCustomObject]@{
                        ResourceGroup = $resourceGroup
                        ResourceName = $resourceName
                        Endpoint = $connectivityEndpoints.sqlOnDemand
                        Type = "Synapse SQL On-Demand Endpoint"
                    }
                }
                
                # Dev endpoint
                if ($connectivityEndpoints.dev) {
                    $findings += [PSCustomObject]@{
                        ResourceGroup = $resourceGroup
                        ResourceName = $resourceName
                        Endpoint = $connectivityEndpoints.dev
                        Type = "Synapse Dev Endpoint"
                    }
                }
            }
            
            # Get the workspace web URL
            $webUrl = $workspace.WorkspaceUrl
            
            if ($webUrl) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = "https://$webUrl.azuresynapse.net"
                    Type = "Synapse Web URL"
                }
            }
            
            # Check for firewall rules
            $firewallRules = Get-AzSynapseFirewallRule -WorkspaceName $resourceName -ResourceGroupName $resourceGroup
            
            if ($firewallRules) {
                foreach ($rule in $firewallRules) {
                    # Check for "Allow All" rule (0.0.0.0 - 255.255.255.255)
                    if ($rule.StartIpAddress -eq "0.0.0.0" -and $rule.EndIpAddress -eq "255.255.255.255") {
                        $findings | Where-Object { $_.ResourceName -eq $resourceName } | ForEach-Object {
                            $_.Type = "$($_.Type) (Public Access)"
                        }
                        
                        $findings += [PSCustomObject]@{
                            ResourceGroup = $resourceGroup
                            ResourceName = $resourceName
                            Endpoint = "All IPs (0.0.0.0-255.255.255.255)"
                            Type = "Allowed IP Range"
                        }
                    }
                    # Check for "Allow Azure Services" rule
                    elseif ($rule.Name -eq "AllowAllWindowsAzureIps") {
                        $findings += [PSCustomObject]@{
                            ResourceGroup = $resourceGroup
                            ResourceName = $resourceName
                            Endpoint = "Azure Services"
                            Type = "Allowed IP Range"
                        }
                    }
                    else {
                        $findings += [PSCustomObject]@{
                            ResourceGroup = $resourceGroup
                            ResourceName = $resourceName
                            Endpoint = "$($rule.StartIpAddress)-$($rule.EndIpAddress)"
                            Type = "Allowed IP Range"
                        }
                    }
                }
            }
            
            # Get SQL pools
            $sqlPools = Get-AzSynapseSqlPool -WorkspaceName $resourceName -ResourceGroupName $resourceGroup
            
            if ($sqlPools) {
                foreach ($pool in $sqlPools) {
                    $poolName = $pool.Name
                    
                    $findings += [PSCustomObject]@{
                        ResourceGroup = $resourceGroup
                        ResourceName = "$resourceName/$poolName"
                        Endpoint = "$resourceName-$poolName.sql.azuresynapse.net"
                        Type = "Synapse SQL Pool"
                    }
                }
            }
            
            # Get Spark pools
            $sparkPools = Get-AzSynapseSparkPool -WorkspaceName $resourceName -ResourceGroupName $resourceGroup
            
            if ($sparkPools) {
                foreach ($pool in $sparkPools) {
                    $poolName = $pool.Name
                    
                    $findings += [PSCustomObject]@{
                        ResourceGroup = $resourceGroup
                        ResourceName = "$resourceName/$poolName"
                        Endpoint = "$resourceName-$poolName.spark.azuresynapse.net"
                        Type = "Synapse Spark Pool"
                    }
                }
            }
        }
    }
    catch {
        Write-Error "Error processing Synapse Analytics: $_"
    }
    
    return $findings
}

function Get-DataExplorerEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all Data Explorer clusters in the current subscription
        $dataExplorerClusters = Get-AzKustoCluster
        
        foreach ($cluster in $dataExplorerClusters) {
            $resourceGroup = $cluster.ResourceGroupName
            $resourceName = $cluster.Name
            
            Write-Verbose "Processing Data Explorer Cluster: $resourceName in $resourceGroup"
            
            # Get the URI
            $uri = $cluster.Uri
            
            if ($uri) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $uri
                    Type = "Data Explorer URI"
                }
            }
            
            # Get the data ingestion URI
            $dataIngestionUri = $cluster.DataIngestionUri
            
            if ($dataIngestionUri) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $dataIngestionUri
                    Type = "Data Explorer Ingestion URI"
                }
            }
            
            # Check for public network access
            $publicNetworkAccess = $cluster.EnablePublicNetworkAccess
            
            if ($publicNetworkAccess -eq "Enabled") {
                $findings | Where-Object { $_.ResourceName -eq $resourceName } | ForEach-Object {
                    $_.Type = "$($_.Type) (Public Access)"
                }
                
                # Check for trusted external tenants
                $trustedExternalTenants = $cluster.TrustedExternalTenants
                
                if ($trustedExternalTenants) {
                    foreach ($tenant in $trustedExternalTenants) {
                        $findings += [PSCustomObject]@{
                            ResourceGroup = $resourceGroup
                            ResourceName = $resourceName
                            Endpoint = $tenant.Value
                            Type = "Trusted External Tenant"
                        }
                    }
                }
            }
            else {
                $findings | Where-Object { $_.ResourceName -eq $resourceName } | ForEach-Object {
                    $_.Type = "$($_.Type) (Private Access)"
                }
            }
            
            # Get the databases
            $databases = Get-AzKustoDatabase -ClusterName $resourceName -ResourceGroupName $resourceGroup
            
            foreach ($database in $databases) {
                $dbName = $database.Name
                
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = "$resourceName/$dbName"
                    Endpoint = "$uri/databases/$dbName"
                    Type = "Data Explorer Database"
                }
            }
        }
    }
    catch {
        Write-Error "Error processing Data Explorer: $_"
    }
    
    return $findings
}

function Get-ApplicationInsightsEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all Application Insights components in the current subscription
        $appInsightsComponents = Get-AzApplicationInsights
        
        foreach ($component in $appInsightsComponents) {
            $resourceGroup = $component.ResourceGroupName
            $resourceName = $component.Name
            
            Write-Verbose "Processing Application Insights: $resourceName in $resourceGroup"
            
            # Get the instrumentation key (sensitive)
            $instrumentationKey = $component.InstrumentationKey
            
            if ($instrumentationKey) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = "Instrumentation Key Available"
                    Type = "Application Insights Key"
                }
            }
            
            # Get the connection string (sensitive)
            $connectionString = $component.ConnectionString
            
            if ($connectionString) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = "Connection String Available"
                    Type = "Application Insights Connection"
                }
            }
            
            # Get the application ID
            $appId = $component.AppId
            
            if ($appId) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $appId
                    Type = "Application Insights ID"
                }
            }
            
            # Add the ingestion endpoint
            $findings += [PSCustomObject]@{
                ResourceGroup = $resourceGroup
                ResourceName = $resourceName
                Endpoint = "dc.applicationinsights.azure.com"
                Type = "Application Insights Ingestion Endpoint"
            }
            
            # Add the Live Metrics endpoint
            $findings += [PSCustomObject]@{
                ResourceGroup = $resourceGroup
                ResourceName = $resourceName
                Endpoint = "rt.applicationinsights.azure.com"
                Type = "Application Insights Live Metrics Endpoint"
            }
        }
    }
    catch {
        Write-Error "Error processing Application Insights: $_"
    }
    
    return $findings
}

Export-ModuleMember -Function Get-SynapseAnalyticsEndpoints, Get-DataExplorerEndpoints, Get-ApplicationInsightsEndpoints
