<#
.SYNOPSIS
    Discovers SQL Databases with externally accessible endpoints.

.DESCRIPTION
    This module identifies Azure SQL Databases and SQL Managed Instances
    with public endpoints and extracts their connection information.

.NOTES
    Author: liarm
    Date: April 20, 2025
#>

function Get-SQLDatabasesEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all SQL servers in the current subscription
        $sqlServers = Get-AzSqlServer
        
        foreach ($sqlServer in $sqlServers) {
            $resourceGroup = $sqlServer.ResourceGroupName
            $resourceName = $sqlServer.ServerName
            
            Write-Verbose "Processing SQL Server: $resourceName in $resourceGroup"
            
            # Get the server endpoint
            $serverEndpoint = "$resourceName.database.windows.net"
            
            # Check firewall rules to determine if public access is enabled
            $firewallRules = Get-AzSqlServerFirewallRule -ResourceGroupName $resourceGroup -ServerName $resourceName
            
            $publicAccessEnabled = $false
            $allowedIpRanges = @()
            
            foreach ($rule in $firewallRules) {
                # Check for "Allow All" rule (0.0.0.0 - 255.255.255.255)
                if ($rule.StartIpAddress -eq "0.0.0.0" -and $rule.EndIpAddress -eq "255.255.255.255") {
                    $publicAccessEnabled = $true
                    $allowedIpRanges += "All IPs (0.0.0.0-255.255.255.255)"
                }
                # Check for "Allow Azure Services" rule
                elseif ($rule.StartIpAddress -eq "0.0.0.0" -and $rule.EndIpAddress -eq "0.0.0.0") {
                    $allowedIpRanges += "Azure Services"
                }
                else {
                    $allowedIpRanges += "$($rule.StartIpAddress)-$($rule.EndIpAddress)"
                }
            }
            
            # Add server endpoint with access information
            if ($publicAccessEnabled) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $serverEndpoint
                    Type = "SQL Server (Public Access)"
                }
            }
            else {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $serverEndpoint
                    Type = "SQL Server (Restricted Access)"
                }
            }
            
            # Add allowed IP ranges as separate findings
            foreach ($ipRange in $allowedIpRanges) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $ipRange
                    Type = "Allowed IP Range"
                }
            }
            
            # Get databases for this server
            $databases = Get-AzSqlDatabase -ResourceGroupName $resourceGroup -ServerName $resourceName | Where-Object { $_.DatabaseName -ne "master" }
            
            foreach ($database in $databases) {
                $dbName = $database.DatabaseName
                
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = "$resourceName/$dbName"
                    Endpoint = "$serverEndpoint/$dbName"
                    Type = "SQL Database"
                }
            }
        }
        
        # Get all SQL Managed Instances in the current subscription
        $managedInstances = Get-AzSqlInstance
        
        foreach ($instance in $managedInstances) {
            $resourceGroup = $instance.ResourceGroupName
            $resourceName = $instance.ManagedInstanceName
            
            Write-Verbose "Processing SQL Managed Instance: $resourceName in $resourceGroup"
            
            # Get the instance endpoint
            $instanceEndpoint = $instance.FullyQualifiedDomainName
            
            $findings += [PSCustomObject]@{
                ResourceGroup = $resourceGroup
                ResourceName = $resourceName
                Endpoint = $instanceEndpoint
                Type = "SQL Managed Instance"
            }
        }
    }
    catch {
        Write-Error "Error processing SQL Databases: $_"
    }
    
    return $findings
}

Export-ModuleMember -Function Get-SQLDatabasesEndpoints
