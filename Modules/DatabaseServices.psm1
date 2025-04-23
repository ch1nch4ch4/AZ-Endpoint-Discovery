<#
.SYNOPSIS
    Discovers database services with externally accessible endpoints.

.DESCRIPTION
    This module identifies Azure database services like Redis Cache, Cosmos DB,
    and extracts their endpoint information.

.NOTES
    Author: liarm
    Date: April 20, 2025
#>

function Get-RedisCacheEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all Redis Cache instances in the current subscription
        $redisCaches = Get-AzRedisCache
        
        foreach ($redisCache in $redisCaches) {
            $resourceGroup = $redisCache.ResourceGroupName
            $resourceName = $redisCache.Name
            
            Write-Verbose "Processing Redis Cache: $resourceName in $resourceGroup"
            
            # Get the hostname
            $hostname = $redisCache.HostName
            
            if ($hostname) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $hostname
                    Type = "Redis Cache Hostname"
                }
            }
            
            # Get the SSL port
            $sslPort = $redisCache.SslPort
            
            if ($sslPort) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = "$hostname`:$sslPort"
                    Type = "Redis Cache SSL Endpoint"
                }
            }
            
            # Get the non-SSL port
            $port = $redisCache.Port
            
            if ($port) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = "$hostname`:$port"
                    Type = "Redis Cache Non-SSL Endpoint"
                }
            }
            
            # Check if public network access is enabled
            if ($redisCache.PublicNetworkAccess -eq "Enabled") {
                $findings | Where-Object { $_.ResourceName -eq $resourceName } | ForEach-Object {
                    $_.Type = "$($_.Type) (Public Access)"
                }
            }
            else {
                $findings | Where-Object { $_.ResourceName -eq $resourceName } | ForEach-Object {
                    $_.Type = "$($_.Type) (Private Access)"
                }
            }
        }
    }
    catch {
        Write-Error "Error processing Redis Cache: $_"
    }
    
    return $findings
}

function Get-CosmosDBEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all Cosmos DB accounts in the current subscription
        $cosmosDBAccounts = Get-AzResource -ResourceType "Microsoft.DocumentDB/databaseAccounts"
        
        foreach ($account in $cosmosDBAccounts) {
            $resourceGroup = $account.ResourceGroupName
            $accountName = $account.Name
            
            # For CosmosDB, we can construct the endpoint URL based on the account name
            $findings += [PSCustomObject]@{
                ResourceGroup = $resourceGroup
                ResourceName = $accountName
                Endpoint = "$accountName.documents.azure.com"
                Type = "FQDN"
            }
            
            Write-Verbose "Found CosmosDB account: $accountName with endpoint $accountName.documents.azure.com"
        }
    }
    catch {
        Write-Error "Error getting CosmosDB endpoints: $_"
    }
    
    return $findings
}

Export-ModuleMember -Function Get-RedisCacheEndpoints, Get-CosmosDBEndpoints
