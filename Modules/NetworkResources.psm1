<#
.SYNOPSIS
    Discovers networking resources with externally accessible endpoints.

.DESCRIPTION
    This module identifies Azure networking resources like Application Gateways,
    Load Balancers, and Traffic Manager profiles that expose endpoints to the internet.

.NOTES
    Author: liarm
    Date: April 20, 2025
#>

function Get-ApplicationGatewaysEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all Application Gateways in the current subscription using Resource Manager API
        $appGateways = Get-AzResource -ResourceType "Microsoft.Network/applicationGateways" -ErrorAction SilentlyContinue
        
        if (-not $appGateways) {
            Write-Verbose "No Application Gateways found in the current subscription."
            return $findings
        }
        
        foreach ($gateway in $appGateways) {
            $resourceGroup = $gateway.ResourceGroupName
            $resourceName = $gateway.Name
            
            Write-Verbose "Processing Application Gateway: $($resourceName) in $($resourceGroup)"
            
            # Get gateway details using Resource Manager API
            $gatewayDetails = Get-AzResource -ResourceGroupName $resourceGroup -ResourceType "Microsoft.Network/applicationGateways" -Name $resourceName -ExpandProperties -ErrorAction SilentlyContinue
            
            if ($gatewayDetails) {
                # Add the application gateway itself
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = "N/A"
                    Type = "Application Gateway"
                }
                
                # Check for frontend IP configurations
                if ($gatewayDetails.Properties.frontendIPConfigurations) {
                    foreach ($frontendIP in $gatewayDetails.Properties.frontendIPConfigurations) {
                        $frontendName = $frontendIP.name
                        
                        # Check if this frontend has a public IP
                        if ($frontendIP.properties.publicIPAddress -and $frontendIP.properties.publicIPAddress.id) {
                            # Extract public IP resource name from the ID
                            $publicIpId = $frontendIP.properties.publicIPAddress.id
                            $publicIpName = $publicIpId.Split('/')[-1]
                            
                            # Get the public IP address resource
                            $publicIp = Get-AzPublicIpAddress -ResourceGroupName $resourceGroup -Name $publicIpName -ErrorAction SilentlyContinue
                            
                            if ($publicIp -and $publicIp.IpAddress -and $publicIp.IpAddress -ne "Dynamic") {
                                $findings += [PSCustomObject]@{
                                    ResourceGroup = $resourceGroup
                                    ResourceName = "$($resourceName)/$($frontendName)"
                                    Endpoint = $publicIp.IpAddress
                                    Type = "Application Gateway Public IP"
                                }
                                
                                # If the public IP has a DNS name, add it as well
                                if ($publicIp.DnsSettings -and $publicIp.DnsSettings.Fqdn) {
                                    $findings += [PSCustomObject]@{
                                        ResourceGroup = $resourceGroup
                                        ResourceName = "$($resourceName)/$($frontendName)"
                                        Endpoint = $publicIp.DnsSettings.Fqdn
                                        Type = "Application Gateway DNS"
                                    }
                                }
                            }
                        }
                    }
                }
                
                # Check for HTTP listeners
                if ($gatewayDetails.Properties.httpListeners) {
                    foreach ($listener in $gatewayDetails.Properties.httpListeners) {
                        $listenerName = $listener.name
                        $protocol = $listener.properties.protocol
                        $hostName = $listener.properties.hostName
                        
                        if ($hostName) {
                            $findings += [PSCustomObject]@{
                                ResourceGroup = $resourceGroup
                                ResourceName = "$($resourceName)/$($listenerName)"
                                Endpoint = $hostName
                                Type = "Application Gateway Listener ($protocol)"
                            }
                        }
                    }
                }
                
                # Check for frontend ports
                if ($gatewayDetails.Properties.frontendPorts) {
                    foreach ($port in $gatewayDetails.Properties.frontendPorts) {
                        $portName = $port.name
                        $portNumber = $port.properties.port
                        
                        $findings += [PSCustomObject]@{
                            ResourceGroup = $resourceGroup
                            ResourceName = "$($resourceName)/$($portName)"
                            Endpoint = $portNumber
                            Type = "Application Gateway Port"
                        }
                    }
                }
                
                # Check for SSL certificates
                if ($gatewayDetails.Properties.sslCertificates) {
                    foreach ($cert in $gatewayDetails.Properties.sslCertificates) {
                        $certName = $cert.name
                        
                        $findings += [PSCustomObject]@{
                            ResourceGroup = $resourceGroup
                            ResourceName = "$($resourceName)/$($certName)"
                            Endpoint = "SSL Certificate"
                            Type = "Application Gateway SSL Certificate"
                        }
                    }
                }
            }
        }
    }
    catch {
        Write-Error "Error processing Application Gateways: $($_)"
    }
    
    return $findings
}

function Get-LoadBalancersEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all load balancers in the current subscription using Resource Manager API
        $loadBalancers = Get-AzResource -ResourceType "Microsoft.Network/loadBalancers" -ErrorAction SilentlyContinue
        
        if (-not $loadBalancers) {
            Write-Verbose "No load balancers found in the current subscription."
            return $findings
        }
        
        foreach ($lb in $loadBalancers) {
            $resourceGroup = $lb.ResourceGroupName
            $resourceName = $lb.Name
            
            Write-Verbose "Processing Load Balancer: $($resourceName) in $($resourceGroup)"
            
            # Get load balancer details using Resource Manager API
            $lbDetails = Get-AzResource -ResourceGroupName $resourceGroup -ResourceType "Microsoft.Network/loadBalancers" -Name $resourceName -ExpandProperties -ErrorAction SilentlyContinue
            
            if ($lbDetails) {
                # Add the load balancer itself
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = "N/A"
                    Type = "Load Balancer"
                }
                
                # Check for frontend IP configurations
                if ($lbDetails.Properties.frontendIPConfigurations) {
                    foreach ($frontendIP in $lbDetails.Properties.frontendIPConfigurations) {
                        $frontendName = $frontendIP.name
                        
                        # Check if this frontend has a public IP
                        if ($frontendIP.properties.publicIPAddress -and $frontendIP.properties.publicIPAddress.id) {
                            # Extract public IP resource name from the ID
                            $publicIpId = $frontendIP.properties.publicIPAddress.id
                            $publicIpName = $publicIpId.Split('/')[-1]
                            
                            # Get the public IP address resource
                            $publicIp = Get-AzPublicIpAddress -ResourceGroupName $resourceGroup -Name $publicIpName -ErrorAction SilentlyContinue
                            
                            if ($publicIp -and $publicIp.IpAddress -and $publicIp.IpAddress -ne "Dynamic") {
                                $findings += [PSCustomObject]@{
                                    ResourceGroup = $resourceGroup
                                    ResourceName = "$($resourceName)/$($frontendName)"
                                    Endpoint = $publicIp.IpAddress
                                    Type = "Load Balancer Public IP"
                                }
                                
                                # If the public IP has a DNS name, add it as well
                                if ($publicIp.DnsSettings -and $publicIp.DnsSettings.Fqdn) {
                                    $findings += [PSCustomObject]@{
                                        ResourceGroup = $resourceGroup
                                        ResourceName = "$($resourceName)/$($frontendName)"
                                        Endpoint = $publicIp.DnsSettings.Fqdn
                                        Type = "Load Balancer DNS"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    catch {
        Write-Error "Error processing Load Balancers: $($_)"
    }
    
    return $findings
}

function Get-TrafficManagerProfilesEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all Traffic Manager profiles in the current subscription
        $trafficManagerProfiles = Get-AzTrafficManagerProfile
        
        foreach ($profile in $trafficManagerProfiles) {
            $resourceGroup = $profile.ResourceGroupName
            $resourceName = $profile.Name
            
            Write-Verbose "Processing Traffic Manager Profile: $resourceName in $resourceGroup"
            
            # Get the profile DNS name
            $profileDnsName = $profile.RelativeDnsName
            if ($profileDnsName) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = "$profileDnsName.trafficmanager.net"
                    Type = "Traffic Manager DNS"
                }
            }
            
            # Get endpoints
            $endpoints = $profile.Endpoints
            
            foreach ($endpoint in $endpoints) {
                $endpointName = $endpoint.Name
                $endpointTarget = $endpoint.Target
                
                if ($endpointTarget) {
                    $findings += [PSCustomObject]@{
                        ResourceGroup = $resourceGroup
                        ResourceName = "$resourceName/$endpointName"
                        Endpoint = $endpointTarget
                        Type = "Traffic Manager Endpoint"
                    }
                }
            }
        }
    }
    catch {
        Write-Error "Error processing Traffic Manager Profiles: $_"
    }
    
    return $findings
}

Export-ModuleMember -Function Get-ApplicationGatewaysEndpoints, Get-LoadBalancersEndpoints, Get-TrafficManagerProfilesEndpoints
