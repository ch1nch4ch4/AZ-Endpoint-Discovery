<#
.SYNOPSIS
    Discovers AKS clusters with externally accessible endpoints.

.DESCRIPTION
    This module identifies Azure Kubernetes Service (AKS) clusters
    and extracts their endpoint information, including API server endpoints
    and any exposed services with public IPs or load balancers.

.NOTES
    Author: liarm
    Date: April 20, 2025
#>

function Get-AKSEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all AKS clusters in the current subscription
        $aksClusters = Get-AzAksCluster
        
        foreach ($cluster in $aksClusters) {
            $resourceGroup = $cluster.ResourceGroupName
            $resourceName = $cluster.Name
            
            Write-Verbose "Processing AKS Cluster: $resourceName in $resourceGroup"
            
            # Get the API server endpoint
            $apiServerEndpoint = $cluster.Fqdn
            
            if ($apiServerEndpoint) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $apiServerEndpoint
                    Type = "AKS API Server"
                }
            }
            
            # Check if API server is publicly accessible or private
            $apiServerAccessProfile = $cluster.ApiServerAccessProfile
            
            if ($apiServerAccessProfile) {
                $enablePrivateCluster = $apiServerAccessProfile.EnablePrivateCluster
                
                if ($enablePrivateCluster -eq $true) {
                    # Update the endpoint type to indicate it's private
                    $findings | Where-Object { $_.ResourceName -eq $resourceName -and $_.Type -eq "AKS API Server" } | ForEach-Object {
                        $_.Type = "AKS API Server (Private)"
                    }
                }
                else {
                    # Check for authorized IP ranges
                    $authorizedIpRanges = $apiServerAccessProfile.AuthorizedIpRanges
                    
                    if ($authorizedIpRanges -and $authorizedIpRanges.Count -gt 0) {
                        foreach ($ipRange in $authorizedIpRanges) {
                            $findings += [PSCustomObject]@{
                                ResourceGroup = $resourceGroup
                                ResourceName = $resourceName
                                Endpoint = $ipRange
                                Type = "Authorized IP Range"
                            }
                        }
                    }
                    else {
                        # If no authorized IP ranges, the API server is publicly accessible
                        $findings | Where-Object { $_.ResourceName -eq $resourceName -and $_.Type -eq "AKS API Server" } | ForEach-Object {
                            $_.Type = "AKS API Server (Public)"
                        }
                    }
                }
            }
            
            # Get the AKS node resource group
            $nodeResourceGroup = $cluster.NodeResourceGroup
            
            if ($nodeResourceGroup) {
                # Get public IPs in the node resource group (these might be used by services)
                $publicIps = Get-AzPublicIpAddress -ResourceGroupName $nodeResourceGroup
                
                foreach ($publicIp in $publicIps) {
                    if ($publicIp.IpAddress -ne "Dynamic" -and $publicIp.IpAddress -ne $null) {
                        # Try to determine what this IP is used for
                        $ipType = "AKS Service IP"
                        
                        # Check if this IP is associated with a load balancer
                        $loadBalancer = Get-AzLoadBalancer -ResourceGroupName $nodeResourceGroup | 
                            Where-Object { $_.FrontendIpConfigurations.PublicIpAddress.Id -eq $publicIp.Id }
                        
                        if ($loadBalancer) {
                            $ipType = "AKS Load Balancer IP"
                        }
                        
                        $findings += [PSCustomObject]@{
                            ResourceGroup = $resourceGroup
                            ResourceName = $resourceName
                            Endpoint = $publicIp.IpAddress
                            Type = $ipType
                        }
                        
                        # If the public IP has a DNS name, add it as well
                        if ($publicIp.DnsSettings -and $publicIp.DnsSettings.Fqdn) {
                            $findings += [PSCustomObject]@{
                                ResourceGroup = $resourceGroup
                                ResourceName = $resourceName
                                Endpoint = $publicIp.DnsSettings.Fqdn
                                Type = "$ipType DNS"
                            }
                        }
                    }
                }
            }
        }
    }
    catch {
        Write-Error "Error processing AKS Clusters: $_"
    }
    
    return $findings
}

Export-ModuleMember -Function Get-AKSEndpoints
