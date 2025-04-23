<#
.SYNOPSIS
    Discovers Azure DevOps services with externally accessible endpoints.

.DESCRIPTION
    This module identifies Azure DevOps organizations and projects
    and extracts their endpoint information.

.NOTES
    Author: liarm
    Date: April 20, 2025
#>

function Get-DevOpsEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Azure DevOps is a bit different from other Azure resources
        # It's not directly managed through Azure Resource Manager
        # We need to use the Azure DevOps REST API or PowerShell module
        
        # Check if the Azure DevOps PowerShell module is installed
        if (-not (Get-Module -ListAvailable -Name "Az.DevOps")) {
            Write-Warning "Az.DevOps module is not installed. Installing..."
            try {
                Install-Module -Name "Az.DevOps" -Scope CurrentUser -Force
            }
            catch {
                Write-Error "Failed to install Az.DevOps module. Error: $_"
                return $findings
            }
        }
        
        # Import the module
        Import-Module -Name "Az.DevOps" -ErrorAction SilentlyContinue
        
        # Try to get the Azure DevOps organizations
        try {
            # Get the organizations
            $organizations = Get-AzDevOpsOrganization
            
            foreach ($org in $organizations) {
                $orgName = $org.Name
                
                $findings += [PSCustomObject]@{
                    ResourceGroup = "N/A"
                    ResourceName = $orgName
                    Endpoint = "https://dev.azure.com/$orgName"
                    Type = "Azure DevOps Organization"
                }
                
                # Get the projects for this organization
                $projects = Get-AzDevOpsProject -Organization $orgName
                
                foreach ($project in $projects) {
                    $projectName = $project.Name
                    $projectId = $project.Id
                    
                    $findings += [PSCustomObject]@{
                        ResourceGroup = "N/A"
                        ResourceName = "$orgName/$projectName"
                        Endpoint = "https://dev.azure.com/$orgName/$projectName"
                        Type = "Azure DevOps Project"
                    }
                    
                    # Add repository URLs
                    $findings += [PSCustomObject]@{
                        ResourceGroup = "N/A"
                        ResourceName = "$orgName/$projectName"
                        Endpoint = "https://dev.azure.com/$orgName/$projectName/_git"
                        Type = "Azure DevOps Git Repositories"
                    }
                    
                    # Add build pipelines URL
                    $findings += [PSCustomObject]@{
                        ResourceGroup = "N/A"
                        ResourceName = "$orgName/$projectName"
                        Endpoint = "https://dev.azure.com/$orgName/$projectName/_build"
                        Type = "Azure DevOps Build Pipelines"
                    }
                    
                    # Add release pipelines URL
                    $findings += [PSCustomObject]@{
                        ResourceGroup = "N/A"
                        ResourceName = "$orgName/$projectName"
                        Endpoint = "https://dev.azure.com/$orgName/$projectName/_release"
                        Type = "Azure DevOps Release Pipelines"
                    }
                    
                    # Add artifacts URL
                    $findings += [PSCustomObject]@{
                        ResourceGroup = "N/A"
                        ResourceName = "$orgName/$projectName"
                        Endpoint = "https://dev.azure.com/$orgName/$projectName/_artifacts"
                        Type = "Azure DevOps Artifacts"
                    }
                }
                
                # Check for service connections
                try {
                    $serviceConnections = Get-AzDevOpsServiceEndpoint -Organization $orgName -Project "*"
                    
                    foreach ($connection in $serviceConnections) {
                        $connectionName = $connection.Name
                        $projectName = $connection.ProjectName
                        $connectionType = $connection.Type
                        
                        $findings += [PSCustomObject]@{
                            ResourceGroup = "N/A"
                            ResourceName = "$orgName/$projectName/$connectionName"
                            Endpoint = $connection.Url
                            Type = "Azure DevOps Service Connection ($connectionType)"
                        }
                    }
                }
                catch {
                    Write-Warning "Failed to get service connections for organization $orgName. Error: $_"
                }
            }
        }
        catch {
            Write-Warning "Failed to get Azure DevOps organizations. Error: $_"
            
            # If we can't get the organizations through the API, we'll provide guidance
            $findings += [PSCustomObject]@{
                ResourceGroup = "N/A"
                ResourceName = "Manual Check Required"
                Endpoint = "https://dev.azure.com/{organization}"
                Type = "Azure DevOps Organization (Manual Check Required)"
            }
        }
        
        # If no findings, add a note
        if ($findings.Count -eq 0) {
            $findings += [PSCustomObject]@{
                ResourceGroup = "N/A"
                ResourceName = "No Azure DevOps organizations found"
                Endpoint = "N/A"
                Type = "Azure DevOps"
            }
        }
    }
    catch {
        Write-Error "Error processing Azure DevOps: $_"
    }
    
    return $findings
}

Export-ModuleMember -Function Get-DevOpsEndpoints
