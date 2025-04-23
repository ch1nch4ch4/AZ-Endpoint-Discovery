<#
.SYNOPSIS
    Discovers network connectivity services with externally accessible endpoints.

.DESCRIPTION
    This module identifies Azure network connectivity services like DNS Zones,
    VPN Gateways, and ExpressRoute Circuits and extracts their endpoint information.

.NOTES
    Author: liarm
    Date: April 20, 2025
#>

function Get-DNSZonesEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all DNS zones in the current subscription using Resource Manager API instead of Get-AzDnsZone
        $dnsZones = Get-AzResource -ResourceType "Microsoft.Network/dnszones" -ErrorAction SilentlyContinue
        
        if (-not $dnsZones) {
            Write-Verbose "No DNS zones found in the current subscription."
            return $findings
        }
        
        foreach ($zone in $dnsZones) {
            $resourceGroup = $zone.ResourceGroupName
            $resourceName = $zone.Name
            
            Write-Verbose "Processing DNS Zone: $($resourceName) in $($resourceGroup)"
            
            # Add the zone itself as an endpoint
            $findings += [PSCustomObject]@{
                ResourceGroup = $resourceGroup
                ResourceName = $resourceName
                Endpoint = $resourceName
                Type = "DNS Zone"
            }
            
            # Get zone details using Resource Manager API
            $zoneDetails = Get-AzResource -ResourceGroupName $resourceGroup -ResourceType "Microsoft.Network/dnszones" -Name $resourceName -ExpandProperties -ErrorAction SilentlyContinue
            
            if ($zoneDetails -and $zoneDetails.Properties.recordSets) {
                foreach ($recordSet in $zoneDetails.Properties.recordSets) {
                    # Extract record name from the ID
                    $recordName = $recordSet.name.Split('/')[-1]
                    $recordType = $recordSet.properties.type
                    
                    # Skip SOA and NS records at the zone apex
                    if (($recordName -eq "@" -or $recordName -eq "") -and ($recordType -eq "SOA" -or $recordType -eq "NS")) {
                        continue
                    }
                    
                    # Construct the full DNS name
                    $fullName = if ($recordName -eq "@" -or $recordName -eq "") {
                        $resourceName
                    }
                    else {
                        "$($recordName).$($resourceName)"
                    }
                    
                    # Add the full DNS name as an endpoint
                    $findings += [PSCustomObject]@{
                        ResourceGroup = $resourceGroup
                        ResourceName = "$($resourceName)/$($recordName)"
                        Endpoint = $fullName
                        Type = "DNS $($recordType) Record"
                    }
                    
                    # Add specific record data if available
                    if ($recordSet.properties.ARecords) {
                        foreach ($record in $recordSet.properties.ARecords) {
                            $findings += [PSCustomObject]@{
                                ResourceGroup = $resourceGroup
                                ResourceName = "$($resourceName)/$($recordName)"
                                Endpoint = $record.ipv4Address
                                Type = "DNS A Record"
                            }
                        }
                    }
                    
                    if ($recordSet.properties.AAAARecords) {
                        foreach ($record in $recordSet.properties.AAAARecords) {
                            $findings += [PSCustomObject]@{
                                ResourceGroup = $resourceGroup
                                ResourceName = "$($resourceName)/$($recordName)"
                                Endpoint = $record.ipv6Address
                                Type = "DNS AAAA Record"
                            }
                        }
                    }
                    
                    if ($recordSet.properties.cnameRecord) {
                        $findings += [PSCustomObject]@{
                            ResourceGroup = $resourceGroup
                            ResourceName = "$($resourceName)/$($recordName)"
                            Endpoint = $recordSet.properties.cnameRecord.cname
                            Type = "DNS CNAME Record"
                        }
                    }
                }
            }
        }
    }
    catch {
        Write-Error "Error processing DNS Zones: $($_)"
    }
    
    return $findings
}

function Get-VPNGatewaysEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all VPN gateways in the current subscription using Get-AzResource to avoid prompts
        $vpnGateways = Get-AzResource -ResourceType "Microsoft.Network/virtualNetworkGateways"
        
        foreach ($gateway in $vpnGateways) {
            $resourceGroup = $gateway.ResourceGroupName
            $resourceName = $gateway.Name
            
            Write-Verbose "Processing VPN Gateway: $($resourceName) in $($resourceGroup)"
            
            # Add basic gateway information
            $findings += [PSCustomObject]@{
                ResourceGroup = $resourceGroup
                ResourceName = $resourceName
                Endpoint = "N/A" # Default value, will be updated if public IP is found
                Type = "VPN Gateway"
            }
            
            # Try to get the public IP address associated with the gateway
            try {
                # Get gateway details using Resource Manager API to avoid parameter prompts
                $gatewayDetails = Get-AzResource -ResourceGroupName $resourceGroup -ResourceType "Microsoft.Network/virtualNetworkGateways" -Name $resourceName -ExpandProperties
                
                if ($gatewayDetails.Properties.ipConfigurations) {
                    foreach ($ipConfig in $gatewayDetails.Properties.ipConfigurations) {
                        if ($ipConfig.properties.publicIPAddress -and $ipConfig.properties.publicIPAddress.id) {
                            # Extract public IP resource name from the ID
                            $publicIpId = $ipConfig.properties.publicIPAddress.id
                            $publicIpName = $publicIpId.Split('/')[-1]
                            
                            # Get the public IP address resource
                            $publicIp = Get-AzPublicIpAddress -ResourceGroupName $resourceGroup -Name $publicIpName -ErrorAction SilentlyContinue
                            
                            if ($publicIp -and $publicIp.IpAddress -and $publicIp.IpAddress -ne "Dynamic") {
                                # Update the endpoint with the public IP
                                $findings | Where-Object { $_.ResourceName -eq $resourceName -and $_.Endpoint -eq "N/A" } | ForEach-Object {
                                    $_.Endpoint = $publicIp.IpAddress
                                    $_.Type = "VPN Gateway (Public IP)"
                                }
                                
                                # Also add as a separate entry
                                $findings += [PSCustomObject]@{
                                    ResourceGroup = $resourceGroup
                                    ResourceName = "$($resourceName)/PublicIP"
                                    Endpoint = $publicIp.IpAddress
                                    Type = "VPN Gateway Public IP"
                                }
                            }
                        }
                    }
                }
                
                # Check for VPN client address pools
                if ($gatewayDetails.Properties.vpnClientConfiguration -and 
                    $gatewayDetails.Properties.vpnClientConfiguration.vpnClientAddressPools -and 
                    $gatewayDetails.Properties.vpnClientConfiguration.vpnClientAddressPools.addressPrefixes) {
                    
                    $addressPrefixes = $gatewayDetails.Properties.vpnClientConfiguration.vpnClientAddressPools.addressPrefixes
                    
                    $findings += [PSCustomObject]@{
                        ResourceGroup = $resourceGroup
                        ResourceName = "$($resourceName)/ClientAddressPool"
                        Endpoint = $addressPrefixes -join ","
                        Type = "VPN Client Address Pool"
                    }
                }
            }
            catch {
                Write-Verbose "Error getting details for VPN Gateway $($resourceName): $($_)"
            }
        }
    }
    catch {
        Write-Error "Error processing VPN Gateways: $($_)"
    }
    
    return $findings
}

function Get-ExpressRouteCircuitsEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all ExpressRoute circuits in the current subscription
        $expressRouteCircuits = Get-AzResource -ResourceType "Microsoft.Network/expressRouteCircuits"
        
        foreach ($circuit in $expressRouteCircuits) {
            $resourceGroup = $circuit.ResourceGroupName
            $resourceName = $circuit.Name
            
            Write-Verbose "Processing ExpressRoute Circuit: $($resourceName) in $($resourceGroup)"
            
            # Get circuit details using Resource Manager API
            $circuitDetails = Get-AzResource -ResourceGroupName $resourceGroup -ResourceType "Microsoft.Network/expressRouteCircuits" -Name $resourceName -ExpandProperties
            
            if ($circuitDetails.Properties.serviceProviderProperties) {
                $serviceProvider = $circuitDetails.Properties.serviceProviderProperties.serviceProviderName
                $peeringLocation = $circuitDetails.Properties.serviceProviderProperties.peeringLocation
                
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = "$($serviceProvider)/$($peeringLocation)"
                    Type = "ExpressRoute Circuit"
                }
            }
            else {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = "N/A"
                    Type = "ExpressRoute Circuit"
                }
            }
            
            # Check for peerings
            if ($circuitDetails.Properties.peerings) {
                foreach ($peering in $circuitDetails.Properties.peerings) {
                    $peeringType = $peering.properties.peeringType
                    $peeringState = $peering.properties.state
                    
                    if ($peeringState -eq "Enabled") {
                        $findings += [PSCustomObject]@{
                            ResourceGroup = $resourceGroup
                            ResourceName = "$($resourceName)/$($peeringType)"
                            Endpoint = "Enabled"
                            Type = "ExpressRoute Peering"
                        }
                    }
                }
            }
            
            # We'll skip getting connections as they require Get-AzVirtualNetworkGatewayConnection
            # which prompts for parameters. Instead, we'll just note the circuit is available.
        }
    }
    catch {
        Write-Error "Error processing ExpressRoute Circuits: $($_)"
    }
    
    return $findings
}

Export-ModuleMember -Function Get-DNSZonesEndpoints, Get-VPNGatewaysEndpoints, Get-ExpressRouteCircuitsEndpoints
