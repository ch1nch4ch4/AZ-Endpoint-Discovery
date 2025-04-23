<#
.SYNOPSIS
    Discovers web services with externally accessible endpoints.

.DESCRIPTION
    This module identifies Azure web services like Static Web Apps and Spring Apps
    and extracts their endpoint information.

.NOTES
    Author: liarm
    Date: April 20, 2025
#>

function Get-StaticWebAppsEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all Static Web Apps in the current subscription
        $staticWebApps = Get-AzStaticWebApp
        
        foreach ($staticWebApp in $staticWebApps) {
            $resourceGroup = $staticWebApp.ResourceGroupName
            $resourceName = $staticWebApp.Name
            
            Write-Verbose "Processing Static Web App: $resourceName in $resourceGroup"
            
            # Get the default hostname
            $defaultHostname = $staticWebApp.DefaultHostname
            
            if ($defaultHostname) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = "https://$defaultHostname"
                    Type = "Static Web App Default Hostname"
                }
            }
            
            # Get custom domains
            $customDomains = Get-AzStaticWebAppCustomDomain -ResourceGroupName $resourceGroup -Name $resourceName
            
            if ($customDomains) {
                foreach ($domain in $customDomains) {
                    $domainName = $domain.DomainName
                    
                    $findings += [PSCustomObject]@{
                        ResourceGroup = $resourceGroup
                        ResourceName = $resourceName
                        Endpoint = $domainName
                        Type = "Static Web App Custom Domain"
                    }
                }
            }
            
            # Get the staging environments
            $stagingEnvironments = Get-AzStaticWebAppBuild -ResourceGroupName $resourceGroup -Name $resourceName
            
            if ($stagingEnvironments) {
                foreach ($environment in $stagingEnvironments) {
                    $envName = $environment.EnvironmentName
                    
                    if ($envName -ne "default") {
                        $findings += [PSCustomObject]@{
                            ResourceGroup = $resourceGroup
                            ResourceName = "$resourceName/$envName"
                            Endpoint = "https://$envName.$defaultHostname"
                            Type = "Static Web App Staging Environment"
                        }
                    }
                }
            }
        }
    }
    catch {
        Write-Error "Error processing Static Web Apps: $_"
    }
    
    return $findings
}

function Get-SpringAppsEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all Spring Apps in the current subscription using Resource Manager API
        $springApps = Get-AzResource -ResourceType "Microsoft.AppPlatform/Spring" -ErrorAction SilentlyContinue
        
        if (-not $springApps) {
            Write-Verbose "No Spring Apps found in the current subscription."
            return $findings
        }
        
        foreach ($app in $springApps) {
            $resourceGroup = $app.ResourceGroupName
            $resourceName = $app.Name
            
            Write-Verbose "Processing Spring App: $($resourceName) in $($resourceGroup)"
            
            # Get Spring App details using Resource Manager API
            $appDetails = Get-AzResource -ResourceGroupName $resourceGroup -ResourceType "Microsoft.AppPlatform/Spring" -Name $resourceName -ExpandProperties -ErrorAction SilentlyContinue
            
            if ($appDetails) {
                # Add the Spring App service itself
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = "N/A"
                    Type = "Spring App Service"
                }
                
                # Check for apps within the Spring Apps service
                if ($appDetails.Properties.properties) {
                    # Get all apps in this Spring Apps service
                    $apps = Get-AzResource -ResourceGroupName $resourceGroup -ResourceType "Microsoft.AppPlatform/Spring/apps" -ParentResource "Spring/$resourceName" -ErrorAction SilentlyContinue
                    
                    foreach ($springApp in $apps) {
                        $appName = $springApp.Name
                        
                        # Get app details
                        $springAppDetails = Get-AzResource -ResourceGroupName $resourceGroup -ResourceType "Microsoft.AppPlatform/Spring/apps" -Name $appName -ParentResource "Spring/$resourceName" -ExpandProperties -ErrorAction SilentlyContinue
                        
                        if ($springAppDetails -and $springAppDetails.Properties.properties -and $springAppDetails.Properties.properties.url) {
                            $url = $springAppDetails.Properties.properties.url
                            
                            $findings += [PSCustomObject]@{
                                ResourceGroup = $resourceGroup
                                ResourceName = "$($resourceName)/$($appName)"
                                Endpoint = $url
                                Type = "Spring App URL"
                            }
                        }
                        
                        # Get all deployments for this app
                        $deployments = Get-AzResource -ResourceGroupName $resourceGroup -ResourceType "Microsoft.AppPlatform/Spring/apps/deployments" -ParentResource "Spring/$resourceName/apps/$appName" -ErrorAction SilentlyContinue
                        
                        foreach ($deployment in $deployments) {
                            $deploymentName = $deployment.Name
                            
                            # Get deployment details
                            $deploymentDetails = Get-AzResource -ResourceGroupName $resourceGroup -ResourceType "Microsoft.AppPlatform/Spring/apps/deployments" -Name $deploymentName -ParentResource "Spring/$resourceName/apps/$appName" -ExpandProperties -ErrorAction SilentlyContinue
                            
                            if ($deploymentDetails -and $deploymentDetails.Properties.properties -and $deploymentDetails.Properties.properties.active) {
                                $findings += [PSCustomObject]@{
                                    ResourceGroup = $resourceGroup
                                    ResourceName = "$($resourceName)/$($appName)/$($deploymentName)"
                                    Endpoint = "Active Deployment"
                                    Type = "Spring App Deployment"
                                }
                            }
                        }
                    }
                }
                
                # Check for custom domains
                if ($appDetails.Properties.customDomains) {
                    foreach ($domain in $appDetails.Properties.customDomains) {
                        $findings += [PSCustomObject]@{
                            ResourceGroup = $resourceGroup
                            ResourceName = "$($resourceName)/CustomDomain"
                            Endpoint = $domain.name
                            Type = "Spring App Custom Domain"
                        }
                    }
                }
            }
        }
    }
    catch {
        Write-Error "Error processing Spring Apps: $($_)"
    }
    
    return $findings
}

function Get-BatchEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all Batch accounts in the current subscription
        $batchAccounts = Get-AzBatchAccount
        
        foreach ($batchAccount in $batchAccounts) {
            $resourceGroup = $batchAccount.ResourceGroupName
            $resourceName = $batchAccount.AccountName
            
            Write-Verbose "Processing Batch Account: $resourceName in $resourceGroup"
            
            # Get the account endpoint
            $accountEndpoint = $batchAccount.AccountEndpoint
            
            if ($accountEndpoint) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = "https://$accountEndpoint"
                    Type = "Batch Account Endpoint"
                }
            }
            
            # Check for public network access
            $publicNetworkAccess = $batchAccount.PublicNetworkAccess
            
            if ($publicNetworkAccess -eq "Enabled") {
                $findings | Where-Object { $_.ResourceName -eq $resourceName } | ForEach-Object {
                    $_.Type = "$($_.Type) (Public Access)"
                }
                
                # Check for allowed IP ranges
                $networkAllowList = $batchAccount.NetworkAllowList
                
                if ($networkAllowList -and $networkAllowList.Count -gt 0) {
                    foreach ($allowedIp in $networkAllowList) {
                        $findings += [PSCustomObject]@{
                            ResourceGroup = $resourceGroup
                            ResourceName = $resourceName
                            Endpoint = $allowedIp.Range
                            Type = "Allowed IP Range"
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
            
            # Get the pools - Check if BatchContext is available before using it
            if ($batchAccount.Context) {
                try {
                    $pools = Get-AzBatchPool -BatchContext $batchAccount.Context -ErrorAction Stop
                    
                    foreach ($pool in $pools) {
                        $poolName = $pool.Name
                        
                        $findings += [PSCustomObject]@{
                            ResourceGroup = $resourceGroup
                            ResourceName = "$resourceName/$poolName"
                            Endpoint = "https://$accountEndpoint/pools/$poolName"
                            Type = "Batch Pool"
                        }
                    }
                }
                catch {
                    Write-Verbose ("Error retrieving pools for Batch account {0}. Error: {1}" -f $resourceName, $_)
                }
            }
            else {
                Write-Verbose ("BatchContext not available for account {0}. Skipping pool discovery." -f $resourceName)
                
                # Try to get the account key and create a context
                try {
                    $keys = Get-AzBatchAccountKey -AccountName $resourceName -ResourceGroupName $resourceGroup
                    if ($keys -and $accountEndpoint) {
                        $context = New-AzBatchAccountContext -AccountName $resourceName -AccountKey $keys.PrimaryAccountKey -AccountEndpoint $accountEndpoint
                        
                        $pools = Get-AzBatchPool -BatchContext $context -ErrorAction Stop
                        
                        foreach ($pool in $pools) {
                            $poolName = $pool.Name
                            
                            $findings += [PSCustomObject]@{
                                ResourceGroup = $resourceGroup
                                ResourceName = "$resourceName/$poolName"
                                Endpoint = "https://$accountEndpoint/pools/$poolName"
                                Type = "Batch Pool"
                            }
                        }
                    }
                }
                catch {
                    Write-Verbose ("Failed to create BatchContext for account {0}. Error: {1}" -f $resourceName, $_)
                }
            }
        }
    }
    catch {
        Write-Error ("Error processing Batch: {0}" -f $_)
    }
    
    return $findings
}

function Get-DedicatedHostsEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all dedicated host groups in the current subscription
        $hostGroups = Get-AzHostGroup
        
        foreach ($hostGroup in $hostGroups) {
            $resourceGroup = $hostGroup.ResourceGroupName
            $resourceName = $hostGroup.Name
            
            Write-Verbose "Processing Dedicated Host Group: $resourceName in $resourceGroup"
            
            # Add the host group
            $findings += [PSCustomObject]@{
                ResourceGroup = $resourceGroup
                ResourceName = $resourceName
                Endpoint = "N/A"
                Type = "Dedicated Host Group"
            }
            
            # Get the hosts in this group
            $hosts = Get-AzHost -HostGroupName $resourceName -ResourceGroupName $resourceGroup
            
            foreach ($dedicatedHost in $hosts) {
                $hostName = $dedicatedHost.Name
                
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = "$resourceName/$hostName"
                    Endpoint = "N/A"
                    Type = "Dedicated Host"
                }
                
                # Get VMs on this host
                $vms = Get-AzVM | Where-Object { $_.Host -eq $dedicatedHost.Id }
                
                foreach ($vm in $vms) {
                    $vmName = $vm.Name
                    $vmResourceGroup = $vm.ResourceGroupName
                    
                    # Check if the VM has public IP
                    $networkInterfaces = $vm.NetworkProfile.NetworkInterfaces
                    
                    foreach ($nic in $networkInterfaces) {
                        # Extract the NIC ID
                        $nicId = $nic.Id
                        
                        # Get the NIC details
                        $nicResource = Get-AzNetworkInterface -ResourceId $nicId
                        
                        # Check if the NIC has IP configurations
                        if ($nicResource.IpConfigurations) {
                            foreach ($ipConfig in $nicResource.IpConfigurations) {
                                # Check if the IP configuration has a public IP address
                                if ($ipConfig.PublicIpAddress) {
                                    $publicIpId = $ipConfig.PublicIpAddress.Id
                                    
                                    # Get the public IP address details
                                    $publicIp = Get-AzPublicIpAddress -ResourceId $publicIpId
                                    
                                    if ($publicIp -and $publicIp.IpAddress -ne "Dynamic" -and $null -ne $publicIp.IpAddress) {
                                        $findings += [PSCustomObject]@{
                                            ResourceGroup = $vmResourceGroup
                                            ResourceName = $vmName
                                            Endpoint = $publicIp.IpAddress
                                            Type = "VM on Dedicated Host Public IP"
                                        }
                                        
                                        # If the VM has a DNS name, add it as well
                                        if ($publicIp.DnsSettings -and $publicIp.DnsSettings.Fqdn) {
                                            $findings += [PSCustomObject]@{
                                                ResourceGroup = $vmResourceGroup
                                                ResourceName = $vmName
                                                Endpoint = $publicIp.DnsSettings.Fqdn
                                                Type = "VM on Dedicated Host FQDN"
                                            }
                                        }
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
        Write-Error "Error processing Dedicated Hosts: $_"
    }
    
    return $findings
}

Export-ModuleMember -Function Get-StaticWebAppsEndpoints, Get-SpringAppsEndpoints, Get-BatchEndpoints, Get-DedicatedHostsEndpoints
