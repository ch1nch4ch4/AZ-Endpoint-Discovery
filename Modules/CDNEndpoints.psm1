<#
.SYNOPSIS
    Discovers CDN Endpoints with externally accessible URLs.

.DESCRIPTION
    This module identifies Azure CDN profiles and endpoints and extracts their URL information.

.NOTES
    Author: liarm
    Date: April 20, 2025
#>

function Get-CDNEndpointsEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all CDN profiles in the current subscription
        $cdnProfiles = Get-AzCdnProfile
        
        foreach ($profile in $cdnProfiles) {
            $resourceGroup = $profile.ResourceGroupName
            $profileName = $profile.Name
            
            Write-Verbose "Processing CDN Profile: $profileName in $resourceGroup"
            
            # Get all endpoints for this profile
            $endpoints = Get-AzCdnEndpoint -ProfileName $profileName -ResourceGroupName $resourceGroup
            
            foreach ($endpoint in $endpoints) {
                $endpointName = $endpoint.Name
                
                # Get the endpoint hostname
                $hostName = $endpoint.HostName
                
                if ($hostName) {
                    $findings += [PSCustomObject]@{
                        ResourceGroup = $resourceGroup
                        ResourceName = "$profileName/$endpointName"
                        Endpoint = $hostName
                        Type = "CDN Endpoint"
                    }
                }
                
                # Check for custom domains
                $customDomains = Get-AzCdnCustomDomain -EndpointName $endpointName -ProfileName $profileName -ResourceGroupName $resourceGroup -ErrorAction SilentlyContinue
                
                if ($customDomains) {
                    foreach ($domain in $customDomains) {
                        $domainName = $domain.HostName
                        
                        if ($domainName) {
                            $findings += [PSCustomObject]@{
                                ResourceGroup = $resourceGroup
                                ResourceName = "$profileName/$endpointName"
                                Endpoint = $domainName
                                Type = "CDN Custom Domain"
                            }
                        }
                    }
                }
                
                # Get the origin information
                $origins = $endpoint.Origins
                
                if ($origins) {
                    foreach ($origin in $origins) {
                        $originHostName = $origin.HostName
                        
                        if ($originHostName) {
                            $findings += [PSCustomObject]@{
                                ResourceGroup = $resourceGroup
                                ResourceName = "$profileName/$endpointName"
                                Endpoint = $originHostName
                                Type = "CDN Origin"
                            }
                        }
                    }
                }
            }
        }
    }
    catch {
        Write-Error "Error processing CDN Endpoints: $_"
    }
    
    return $findings
}

Export-ModuleMember -Function Get-CDNEndpointsEndpoints
