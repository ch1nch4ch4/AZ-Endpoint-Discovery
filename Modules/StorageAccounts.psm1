<#
.SYNOPSIS
    Discovers Storage Accounts with externally accessible endpoints.

.DESCRIPTION
    This module identifies Azure Storage Accounts with public access enabled
    and extracts their endpoint information for blob, file, table, and queue services.

.NOTES
    Author: liarm
    Date: April 20, 2025
#>

function Get-StorageAccountsEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all storage accounts in the current subscription
        $storageAccounts = Get-AzStorageAccount
        
        foreach ($storageAccount in $storageAccounts) {
            $resourceGroup = $storageAccount.ResourceGroupName
            $resourceName = $storageAccount.StorageAccountName
            
            Write-Verbose "Processing Storage Account: $resourceName in $resourceGroup"
            
            # Check if public blob access is enabled
            if ($storageAccount.AllowBlobPublicAccess -eq $true) {
                # Add blob endpoint
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $storageAccount.PrimaryEndpoints.Blob
                    Type = "Blob Endpoint (Public Access)"
                }
            }
            else {
                # Still add the endpoint but mark it as restricted
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $storageAccount.PrimaryEndpoints.Blob
                    Type = "Blob Endpoint (Restricted Access)"
                }
            }
            
            # Add other endpoints
            if ($storageAccount.PrimaryEndpoints.File) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $storageAccount.PrimaryEndpoints.File
                    Type = "File Endpoint"
                }
            }
            
            if ($storageAccount.PrimaryEndpoints.Table) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $storageAccount.PrimaryEndpoints.Table
                    Type = "Table Endpoint"
                }
            }
            
            if ($storageAccount.PrimaryEndpoints.Queue) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $storageAccount.PrimaryEndpoints.Queue
                    Type = "Queue Endpoint"
                }
            }
            
            if ($storageAccount.PrimaryEndpoints.Web) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $storageAccount.PrimaryEndpoints.Web
                    Type = "Static Website Endpoint"
                }
            }
            
            # Check for custom domains
            $customDomain = $storageAccount.CustomDomain
            if ($customDomain -and $customDomain.Name) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $customDomain.Name
                    Type = "Custom Domain"
                }
            }
            
            # Check for network rules
            $networkRuleSet = $storageAccount.NetworkRuleSet
            if ($networkRuleSet) {
                # Check default action
                if ($networkRuleSet.DefaultAction -eq "Allow") {
                    $findings | Where-Object { $_.ResourceName -eq $resourceName } | ForEach-Object {
                        $_.Type = "$($_.Type) (Network: Allow All)"
                    }
                }
                
                # Check IP rules
                if ($networkRuleSet.IpRules) {
                    foreach ($ipRule in $networkRuleSet.IpRules) {
                        $findings += [PSCustomObject]@{
                            ResourceGroup = $resourceGroup
                            ResourceName = $resourceName
                            Endpoint = $ipRule.IPAddressOrRange
                            Type = "Allowed IP Range"
                        }
                    }
                }
            }
        }
    }
    catch {
        Write-Error "Error processing Storage Accounts: $_"
    }
    
    return $findings
}

Export-ModuleMember -Function Get-StorageAccountsEndpoints
