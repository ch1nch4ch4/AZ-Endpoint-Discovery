<#
.SYNOPSIS
    Discovers API Management services with externally accessible endpoints.

.DESCRIPTION
    This module identifies Azure API Management services and extracts their endpoint information,
    including gateway URLs, developer portal URLs, and management endpoints.

.NOTES
    Author: liarm
    Date: April 20, 2025
#>

function Get-APIManagementServicesEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all API Management services in the current subscription
        $apiManagementServices = Get-AzApiManagement
        
        foreach ($apiManagement in $apiManagementServices) {
            $resourceGroup = $apiManagement.ResourceGroupName
            $resourceName = $apiManagement.Name
            
            Write-Verbose "Processing API Management Service: $resourceName in $resourceGroup"
            
            # Get the gateway URL
            $gatewayUrl = $apiManagement.GatewayUrl
            if ($gatewayUrl) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $gatewayUrl
                    Type = "API Gateway URL"
                }
            }
            
            # Get the developer portal URL
            $portalUrl = $apiManagement.PortalUrl
            if ($portalUrl) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $portalUrl
                    Type = "Developer Portal URL"
                }
            }
            
            # Get the management URL
            $managementUrl = $apiManagement.ManagementUrl
            if ($managementUrl) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $managementUrl
                    Type = "Management URL"
                }
            }
            
            # Get the SCM URL
            $scmUrl = $apiManagement.ScmUrl
            if ($scmUrl) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $scmUrl
                    Type = "SCM URL"
                }
            }
            
            # Check for custom domains
            $hostnames = Get-AzApiManagementCustomHostnameConfiguration -Context $apiManagement.Context
            
            if ($hostnames) {
                foreach ($hostname in $hostnames) {
                    $findings += [PSCustomObject]@{
                        ResourceGroup = $resourceGroup
                        ResourceName = $resourceName
                        Endpoint = $hostname.Hostname
                        Type = "Custom Domain ($($hostname.HostnameType))"
                    }
                }
            }
            
            # Check for public IP addresses
            $publicIps = $apiManagement.PublicIPAddresses
            
            if ($publicIps) {
                foreach ($publicIp in $publicIps) {
                    $findings += [PSCustomObject]@{
                        ResourceGroup = $resourceGroup
                        ResourceName = $resourceName
                        Endpoint = $publicIp
                        Type = "Public IP"
                    }
                }
            }
            
            # Check for virtual network configuration
            $virtualNetworkType = $apiManagement.VirtualNetworkType
            
            if ($virtualNetworkType -eq "External") {
                $findings | Where-Object { $_.ResourceName -eq $resourceName } | ForEach-Object {
                    $_.Type = "$($_.Type) (External VNET)"
                }
            }
            elseif ($virtualNetworkType -eq "Internal") {
                $findings | Where-Object { $_.ResourceName -eq $resourceName } | ForEach-Object {
                    $_.Type = "$($_.Type) (Internal VNET)"
                }
            }
        }
    }
    catch {
        Write-Error "Error processing API Management Services: $_"
    }
    
    return $findings
}

Export-ModuleMember -Function Get-APIManagementServicesEndpoints
