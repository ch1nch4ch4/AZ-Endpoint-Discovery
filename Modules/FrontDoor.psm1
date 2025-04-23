<#
.SYNOPSIS
    Discovers Azure Front Door services with externally accessible endpoints.

.DESCRIPTION
    This module identifies Azure Front Door services and extracts their endpoint information,
    including frontend hosts, routing rules, and backend pools.

.NOTES
    Author: liarm
    Date: April 20, 2025
#>

function Get-AzureFrontDoorEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all Front Door services in the current subscription
        $frontDoors = Get-AzFrontDoor
        
        foreach ($frontDoor in $frontDoors) {
            $resourceGroup = $frontDoor.ResourceGroupName
            $resourceName = $frontDoor.Name
            
            Write-Verbose "Processing Front Door: $resourceName in $resourceGroup"
            
            # Get the frontend endpoints
            $frontendEndpoints = $frontDoor.FrontendEndpoints
            
            foreach ($endpoint in $frontendEndpoints) {
                $endpointName = $endpoint.Name
                $hostName = $endpoint.HostName
                
                if ($hostName) {
                    $findings += [PSCustomObject]@{
                        ResourceGroup = $resourceGroup
                        ResourceName = "$resourceName/$endpointName"
                        Endpoint = $hostName
                        Type = "Front Door Endpoint"
                    }
                }
                
                # Check for custom domains
                if ($endpoint.CustomHttpsConfiguration -and $endpoint.CustomHttpsConfiguration.CertificateSource -ne "FrontDoor") {
                    $findings += [PSCustomObject]@{
                        ResourceGroup = $resourceGroup
                        ResourceName = "$resourceName/$endpointName"
                        Endpoint = $hostName
                        Type = "Front Door Custom Domain (HTTPS)"
                    }
                }
            }
            
            # Get the routing rules to understand traffic routing
            $routingRules = $frontDoor.RoutingRules
            
            foreach ($rule in $routingRules) {
                $ruleName = $rule.Name
                
                # Get the frontend endpoints associated with this rule
                foreach ($frontendEndpoint in $rule.FrontendEndpoints) {
                    $endpointId = $frontendEndpoint.Id
                    $endpointName = $endpointId.Split('/')[-1]
                    
                    # Find the corresponding frontend endpoint
                    $endpoint = $frontDoor.FrontendEndpoints | Where-Object { $_.Name -eq $endpointName }
                    
                    if ($endpoint -and $endpoint.HostName) {
                        $findings += [PSCustomObject]@{
                            ResourceGroup = $resourceGroup
                            ResourceName = "$resourceName/$ruleName"
                            Endpoint = $endpoint.HostName
                            Type = "Front Door Routing Rule"
                        }
                    }
                }
            }
            
            # Get the backend pools to understand where traffic is being routed
            $backendPools = $frontDoor.BackendPools
            
            foreach ($pool in $backendPools) {
                $poolName = $pool.Name
                
                # Get the backends in this pool
                foreach ($backend in $pool.Backends) {
                    $backendHostName = $backend.Address
                    
                    if ($backendHostName) {
                        $findings += [PSCustomObject]@{
                            ResourceGroup = $resourceGroup
                            ResourceName = "$resourceName/$poolName"
                            Endpoint = $backendHostName
                            Type = "Front Door Backend"
                        }
                    }
                }
            }
        }
    }
    catch {
        Write-Error "Error processing Front Door services: $_"
    }
    
    return $findings
}

Export-ModuleMember -Function Get-AzureFrontDoorEndpoints
