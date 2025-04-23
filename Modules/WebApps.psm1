<#
.SYNOPSIS
    Discovers Web Apps with externally accessible endpoints.

.DESCRIPTION
    This module identifies Azure Web Apps and extracts their endpoint information.
    It covers App Service web apps, function apps, and other web-based services.

.NOTES
    Author: liarm
    Date: April 20, 2025
#>

function Get-WebAppsEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all web apps in the current subscription using Resource Manager API
        $webApps = Get-AzResource -ResourceType "Microsoft.Web/sites" -ErrorAction SilentlyContinue
        
        if (-not $webApps) {
            Write-Verbose "No web apps found in the current subscription."
            return $findings
        }
        
        foreach ($webApp in $webApps) {
            $resourceGroup = $webApp.ResourceGroupName
            $resourceName = $webApp.Name
            
            if (-not $resourceGroup -or -not $resourceName) {
                Write-Verbose "Skipping web app with missing resource group or name."
                continue
            }
            
            Write-Verbose "Processing Web App: $($resourceName) in $($resourceGroup)"
            
            # Get web app details using Resource Manager API
            $webAppDetails = Get-AzResource -ResourceGroupName $resourceGroup -ResourceType "Microsoft.Web/sites" -Name $resourceName -ExpandProperties -ErrorAction SilentlyContinue
            
            if ($webAppDetails -and $webAppDetails.Properties.defaultHostName) {
                $hostName = $webAppDetails.Properties.defaultHostName
                
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $hostName
                    Type = "Web App"
                }
                
                # Check for custom domains
                if ($webAppDetails.Properties.hostNames) {
                    foreach ($customDomain in $webAppDetails.Properties.hostNames) {
                        if ($customDomain -ne $hostName) {
                            $findings += [PSCustomObject]@{
                                ResourceGroup = $resourceGroup
                                ResourceName = $resourceName
                                Endpoint = $customDomain
                                Type = "Web App Custom Domain"
                            }
                        }
                    }
                }
                
                # Check if this is a function app
                if ($webAppDetails.Kind -like "*functionapp*") {
                    $findings | Where-Object { $_.ResourceName -eq $resourceName } | ForEach-Object {
                        $_.Type = "Function App"
                    }
                }
                
                # Check if this is a logic app
                if ($webAppDetails.Kind -like "*workflowapp*") {
                    $findings | Where-Object { $_.ResourceName -eq $resourceName } | ForEach-Object {
                        $_.Type = "Logic App"
                    }
                }
            }
        }
    }
    catch {
        Write-Error "Error processing Web Apps: $($_)"
    }
    
    return $findings
}

Export-ModuleMember -Function Get-WebAppsEndpoints
