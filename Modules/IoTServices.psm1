<#
.SYNOPSIS
    Discovers IoT services with externally accessible endpoints.

.DESCRIPTION
    This module identifies Azure IoT services like IoT Hub, Azure Sphere,
    and Digital Twins and extracts their endpoint information.

.NOTES
    Author: liarm
    Date: April 20, 2025
#>

function Get-IoTHubEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all IoT Hubs in the current subscription
        $iotHubs = Get-AzIotHub
        
        foreach ($iotHub in $iotHubs) {
            $resourceGroup = $iotHub.ResourceGroupName
            $resourceName = $iotHub.Name
            
            Write-Verbose "Processing IoT Hub: $resourceName in $resourceGroup"
            
            # Get the hostname
            $hostname = $iotHub.Properties.HostName
            
            if ($hostname) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $hostname
                    Type = "IoT Hub Hostname"
                }
            }
            
            # Get the event hub-compatible endpoint
            $eventHubEndpoint = $iotHub.Properties.EventHubEndpoints.events.Endpoint
            
            if ($eventHubEndpoint) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $eventHubEndpoint
                    Type = "IoT Hub Event Hub Endpoint"
                }
            }
            
            # Check for public network access
            $publicNetworkAccess = $iotHub.Properties.PublicNetworkAccess
            
            if ($publicNetworkAccess -eq "Enabled") {
                $findings | Where-Object { $_.ResourceName -eq $resourceName } | ForEach-Object {
                    $_.Type = "$($_.Type) (Public Access)"
                }
                
                # Check for IP filter rules
                $ipFilterRules = $iotHub.Properties.IPFilterRules
                
                if ($ipFilterRules -and $ipFilterRules.Count -gt 0) {
                    foreach ($rule in $ipFilterRules) {
                        if ($rule.Action -eq "Allow") {
                            $findings += [PSCustomObject]@{
                                ResourceGroup = $resourceGroup
                                ResourceName = $resourceName
                                Endpoint = $rule.IpMask
                                Type = "Allowed IP Range"
                            }
                        }
                    }
                }
                else {
                    $findings += [PSCustomObject]@{
                        ResourceGroup = $resourceGroup
                        ResourceName = $resourceName
                        Endpoint = "0.0.0.0/0"
                        Type = "All IPs Allowed"
                    }
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
        Write-Error "Error processing IoT Hub: $_"
    }
    
    return $findings
}

function Get-AzureSphereEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all Azure Sphere catalogs in the current subscription
        $sphereCatalogs = Get-AzResource -ResourceType "Microsoft.AzureSphere/catalogs"
        
        foreach ($catalog in $sphereCatalogs) {
            $resourceGroup = $catalog.ResourceGroupName
            $resourceName = $catalog.Name
            
            Write-Verbose "Processing Azure Sphere Catalog: $resourceName in $resourceGroup"
            
            # Since Azure Sphere has limited PowerShell cmdlet support,
            # we'll add the known endpoint pattern
            $findings += [PSCustomObject]@{
                ResourceGroup = $resourceGroup
                ResourceName = $resourceName
                Endpoint = "$resourceName.sphere.azure.com"
                Type = "Azure Sphere Catalog"
            }
        }
    }
    catch {
        Write-Error "Error processing Azure Sphere: $_"
    }
    
    return $findings
}

function Get-DigitalTwinsEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all Digital Twins instances in the current subscription using Resource Manager API
        $digitalTwins = Get-AzResource -ResourceType "Microsoft.DigitalTwins/digitalTwinsInstances" -ErrorAction SilentlyContinue
        
        if (-not $digitalTwins) {
            Write-Verbose "No Digital Twins instances found in the current subscription."
            return $findings
        }
        
        foreach ($instance in $digitalTwins) {
            $resourceGroup = $instance.ResourceGroupName
            $resourceName = $instance.Name
            
            Write-Verbose "Processing Digital Twins instance: $($resourceName) in $($resourceGroup)"
            
            # Get instance details using Resource Manager API
            $instanceDetails = Get-AzResource -ResourceGroupName $resourceGroup -ResourceType "Microsoft.DigitalTwins/digitalTwinsInstances" -Name $resourceName -ExpandProperties -ErrorAction SilentlyContinue
            
            if ($instanceDetails) {
                # Get the hostname
                $hostName = $instanceDetails.Properties.hostName
                
                if ($hostName) {
                    $findings += [PSCustomObject]@{
                        ResourceGroup = $resourceGroup
                        ResourceName = $resourceName
                        Endpoint = $hostName
                        Type = "Digital Twins Hostname"
                    }
                    
                    # Add the full URL
                    $findings += [PSCustomObject]@{
                        ResourceGroup = $resourceGroup
                        ResourceName = $resourceName
                        Endpoint = "https://$($hostName)"
                        Type = "Digital Twins URL"
                    }
                }
                
                # Check for public network access
                $publicNetworkAccess = $instanceDetails.Properties.publicNetworkAccess
                
                if ($publicNetworkAccess -eq "Enabled") {
                    $findings += [PSCustomObject]@{
                        ResourceGroup = $resourceGroup
                        ResourceName = $resourceName
                        Endpoint = "Public Access Enabled"
                        Type = "Digital Twins Network Access"
                    }
                }
                
                # Check for private endpoints
                if ($instanceDetails.Properties.privateEndpointConnections) {
                    foreach ($connection in $instanceDetails.Properties.privateEndpointConnections) {
                        if ($connection.properties.privateLinkServiceConnectionState.status -eq "Approved") {
                            $findings += [PSCustomObject]@{
                                ResourceGroup = $resourceGroup
                                ResourceName = $resourceName
                                Endpoint = $connection.properties.privateEndpoint.id
                                Type = "Digital Twins Private Endpoint"
                            }
                        }
                    }
                }
                
                # Get endpoints
                try {
                    $endpoints = Get-AzResource -ResourceGroupName $resourceGroup -ResourceType "Microsoft.DigitalTwins/digitalTwinsInstances/endpoints" -ParentResource "digitalTwinsInstances/$resourceName" -ErrorAction SilentlyContinue
                    
                    foreach ($endpoint in $endpoints) {
                        $endpointName = $endpoint.Name
                        
                        # Get endpoint details
                        $endpointDetails = Get-AzResource -ResourceGroupName $resourceGroup -ResourceType "Microsoft.DigitalTwins/digitalTwinsInstances/endpoints" -Name $endpointName -ParentResource "digitalTwinsInstances/$resourceName" -ExpandProperties -ErrorAction SilentlyContinue
                        
                        if ($endpointDetails) {
                            $findings += [PSCustomObject]@{
                                ResourceGroup = $resourceGroup
                                ResourceName = "$($resourceName)/$($endpointName)"
                                Endpoint = $endpointDetails.Properties.endpointUri
                                Type = "Digital Twins Endpoint"
                            }
                        }
                    }
                }
                catch {
                    Write-Verbose "Error getting endpoints for Digital Twins instance $($resourceName): $($_)"
                }
            }
        }
    }
    catch {
        Write-Error "Error processing Digital Twins: $($_)"
    }
    
    return $findings
}

Export-ModuleMember -Function Get-IoTHubEndpoints, Get-AzureSphereEndpoints, Get-DigitalTwinsEndpoints
