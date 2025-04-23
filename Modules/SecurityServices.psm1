<#
.SYNOPSIS
    Discovers security services with externally accessible endpoints.

.DESCRIPTION
    This module identifies Azure security services like Azure Firewall and Azure Bastion
    and extracts their endpoint information.

.NOTES
    Author: liarm
    Date: April 20, 2025
#>

function Get-AzureFirewallEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all Azure Firewalls in the current subscription using Resource Manager API
        $firewalls = Get-AzResource -ResourceType "Microsoft.Network/azureFirewalls" -ErrorAction SilentlyContinue
        
        if (-not $firewalls) {
            Write-Verbose "No Azure Firewalls found in the current subscription."
            return $findings
        }
        
        foreach ($firewall in $firewalls) {
            $resourceGroup = $firewall.ResourceGroupName
            $resourceName = $firewall.Name
            
            Write-Verbose "Processing Azure Firewall: $($resourceName) in $($resourceGroup)"
            
            # Get firewall details using Resource Manager API
            $firewallDetails = Get-AzResource -ResourceGroupName $resourceGroup -ResourceType "Microsoft.Network/azureFirewalls" -Name $resourceName -ExpandProperties -ErrorAction SilentlyContinue
            
            if ($firewallDetails) {
                # Add the firewall itself
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = "N/A"
                    Type = "Azure Firewall"
                }
                
                # Check for IP configurations
                if ($firewallDetails.Properties.ipConfigurations) {
                    foreach ($ipConfig in $firewallDetails.Properties.ipConfigurations) {
                        $ipConfigName = $ipConfig.name
                        
                        # Check if this configuration has a public IP
                        if ($ipConfig.properties.publicIPAddress -and $ipConfig.properties.publicIPAddress.id) {
                            # Extract public IP resource name from the ID
                            $publicIpId = $ipConfig.properties.publicIPAddress.id
                            $publicIpName = $publicIpId.Split('/')[-1]
                            
                            # Get the public IP address resource
                            $publicIp = Get-AzPublicIpAddress -ResourceGroupName $resourceGroup -Name $publicIpName -ErrorAction SilentlyContinue
                            
                            if ($publicIp -and $publicIp.IpAddress -and $publicIp.IpAddress -ne "Dynamic") {
                                $findings += [PSCustomObject]@{
                                    ResourceGroup = $resourceGroup
                                    ResourceName = "$($resourceName)/$($ipConfigName)"
                                    Endpoint = $publicIp.IpAddress
                                    Type = "Azure Firewall Public IP"
                                }
                                
                                # If the public IP has a DNS name, add it as well
                                if ($publicIp.DnsSettings -and $publicIp.DnsSettings.Fqdn) {
                                    $findings += [PSCustomObject]@{
                                        ResourceGroup = $resourceGroup
                                        ResourceName = "$($resourceName)/$($ipConfigName)"
                                        Endpoint = $publicIp.DnsSettings.Fqdn
                                        Type = "Azure Firewall DNS"
                                    }
                                }
                            }
                        }
                    }
                }
                
                # Check for management IP configuration
                if ($firewallDetails.Properties.managementIpConfiguration -and 
                    $firewallDetails.Properties.managementIpConfiguration.properties.publicIPAddress -and 
                    $firewallDetails.Properties.managementIpConfiguration.properties.publicIPAddress.id) {
                    
                    $mgmtIpConfigName = $firewallDetails.Properties.managementIpConfiguration.name
                    
                    # Extract public IP resource name from the ID
                    $publicIpId = $firewallDetails.Properties.managementIpConfiguration.properties.publicIPAddress.id
                    $publicIpName = $publicIpId.Split('/')[-1]
                    
                    # Get the public IP address resource
                    $publicIp = Get-AzPublicIpAddress -ResourceGroupName $resourceGroup -Name $publicIpName -ErrorAction SilentlyContinue
                    
                    if ($publicIp -and $publicIp.IpAddress -and $publicIp.IpAddress -ne "Dynamic") {
                        $findings += [PSCustomObject]@{
                            ResourceGroup = $resourceGroup
                            ResourceName = "$($resourceName)/$($mgmtIpConfigName)"
                            Endpoint = $publicIp.IpAddress
                            Type = "Azure Firewall Management IP"
                        }
                    }
                }
                
                # Check for firewall policy
                if ($firewallDetails.Properties.firewallPolicy -and $firewallDetails.Properties.firewallPolicy.id) {
                    $policyId = $firewallDetails.Properties.firewallPolicy.id
                    $policyName = $policyId.Split('/')[-1]
                    $policyResourceGroup = $policyId.Split('/')[4]  # Extract resource group from ID
                    
                    $findings += [PSCustomObject]@{
                        ResourceGroup = $resourceGroup
                        ResourceName = "$($resourceName)/Policy"
                        Endpoint = $policyName
                        Type = "Azure Firewall Policy"
                    }
                }
            }
        }
    }
    catch {
        Write-Error "Error processing Azure Firewall: $($_)"
    }
    
    return $findings
}

function Get-AzureBastionEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all Azure Bastion hosts in the current subscription using Resource Manager API
        $bastionHosts = Get-AzResource -ResourceType "Microsoft.Network/bastionHosts" -ErrorAction SilentlyContinue
        
        if (-not $bastionHosts) {
            Write-Verbose "No Azure Bastion hosts found in the current subscription."
            return $findings
        }
        
        foreach ($bastion in $bastionHosts) {
            $resourceGroup = $bastion.ResourceGroupName
            $resourceName = $bastion.Name
            
            Write-Verbose "Processing Azure Bastion: $($resourceName) in $($resourceGroup)"
            
            # Get bastion details using Resource Manager API
            $bastionDetails = Get-AzResource -ResourceGroupName $resourceGroup -ResourceType "Microsoft.Network/bastionHosts" -Name $resourceName -ExpandProperties -ErrorAction SilentlyContinue
            
            if ($bastionDetails) {
                # Add the bastion host itself
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = "N/A"
                    Type = "Azure Bastion"
                }
                
                # Check for public IP configuration
                if ($bastionDetails.Properties.ipConfigurations -and 
                    $bastionDetails.Properties.ipConfigurations[0].properties.publicIPAddress -and 
                    $bastionDetails.Properties.ipConfigurations[0].properties.publicIPAddress.id) {
                    
                    # Extract public IP resource name from the ID
                    $publicIpId = $bastionDetails.Properties.ipConfigurations[0].properties.publicIPAddress.id
                    $publicIpName = $publicIpId.Split('/')[-1]
                    
                    # Get the public IP address resource
                    $publicIp = Get-AzPublicIpAddress -ResourceGroupName $resourceGroup -Name $publicIpName -ErrorAction SilentlyContinue
                    
                    if ($publicIp -and $publicIp.IpAddress -and $publicIp.IpAddress -ne "Dynamic") {
                        $findings += [PSCustomObject]@{
                            ResourceGroup = $resourceGroup
                            ResourceName = "$($resourceName)/PublicIP"
                            Endpoint = $publicIp.IpAddress
                            Type = "Azure Bastion Public IP"
                        }
                        
                        # If the public IP has a DNS name, add it as well
                        if ($publicIp.DnsSettings -and $publicIp.DnsSettings.Fqdn) {
                            $findings += [PSCustomObject]@{
                                ResourceGroup = $resourceGroup
                                ResourceName = "$($resourceName)/DNS"
                                Endpoint = $publicIp.DnsSettings.Fqdn
                                Type = "Azure Bastion DNS"
                            }
                        }
                    }
                }
            }
        }
    }
    catch {
        Write-Error "Error processing Azure Bastion: $($_)"
    }
    
    return $findings
}

function Get-SignalRServiceEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all SignalR services in the current subscription
        $signalRServices = Get-AzSignalR
        
        foreach ($signalR in $signalRServices) {
            $resourceGroup = $signalR.ResourceGroupName
            $resourceName = $signalR.Name
            
            Write-Verbose "Processing SignalR Service: $resourceName in $resourceGroup"
            
            # Get the hostname
            $hostname = $signalR.HostName
            
            if ($hostname) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $hostname
                    Type = "SignalR Service Hostname"
                }
            }
            
            # Get the external endpoint
            $externalEndpoint = $signalR.ExternalIP
            
            if ($externalEndpoint) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $externalEndpoint
                    Type = "SignalR Service External IP"
                }
            }
            
            # Check for public network access
            $publicNetworkAccess = $signalR.PublicNetworkAccess
            
            if ($publicNetworkAccess -eq "Enabled") {
                $findings | Where-Object { $_.ResourceName -eq $resourceName } | ForEach-Object {
                    $_.Type = "$($_.Type) (Public Access)"
                }
                
                # Check for allowed origins
                $cors = $signalR.Cors
                
                if ($cors -and $cors.AllowedOrigins) {
                    foreach ($origin in $cors.AllowedOrigins) {
                        if ($origin -ne "*") {
                            $findings += [PSCustomObject]@{
                                ResourceGroup = $resourceGroup
                                ResourceName = $resourceName
                                Endpoint = $origin
                                Type = "SignalR Allowed Origin"
                            }
                        }
                        else {
                            $findings += [PSCustomObject]@{
                                ResourceGroup = $resourceGroup
                                ResourceName = $resourceName
                                Endpoint = "*"
                                Type = "SignalR All Origins Allowed"
                            }
                        }
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
        Write-Error "Error processing SignalR Service: $_"
    }
    
    return $findings
}

Export-ModuleMember -Function Get-AzureFirewallEndpoints, Get-AzureBastionEndpoints, Get-SignalRServiceEndpoints
