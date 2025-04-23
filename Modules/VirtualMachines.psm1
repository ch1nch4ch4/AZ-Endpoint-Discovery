<#
.SYNOPSIS
    Discovers Virtual Machines with externally accessible endpoints.

.DESCRIPTION
    This module identifies Azure Virtual Machines with public IP addresses
    and extracts their endpoint information.

.NOTES
    Author: liarm
    Date: April 20, 2025
#>

function Get-VirtualMachinesEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Ensure required modules are loaded
        Import-Module Az.Network -ErrorAction Stop
        
        # Get all VMs in the current subscription
        $vms = Get-AzVM
        
        foreach ($vm in $vms) {
            $resourceGroup = $vm.ResourceGroupName
            $resourceName = $vm.Name
            
            Write-Verbose "Processing VM: $resourceName in $resourceGroup"
            
            # Get network interfaces for the VM
            $networkInterfaces = $vm.NetworkProfile.NetworkInterfaces
            
            foreach ($nic in $networkInterfaces) {
                # Extract the NIC ID
                $nicId = $nic.Id
                
                if (-not $nicId) {
                    Write-Verbose "Skipping null NIC ID for VM: $resourceName"
                    continue
                }
                
                # Get the NIC details - parse the resource ID to extract resource group and name
                try {
                    if ($nicId -match "/resourceGroups/([^/]+)/providers/Microsoft.Network/networkInterfaces/([^/]+)") {
                        $nicRg = $Matches[1]
                        $nicName = $Matches[2]
                        $nicResource = Get-AzNetworkInterface -ResourceGroupName $nicRg -Name $nicName
                    } else {
                        Write-Warning "Could not parse NIC ID: $nicId"
                        continue
                    }
                    
                    # Check if the NIC has IP configurations
                    if ($nicResource.IpConfigurations) {
                        foreach ($ipConfig in $nicResource.IpConfigurations) {
                            # Check if the IP configuration has a public IP address
                            if ($ipConfig.PublicIpAddress) {
                                $publicIpId = $ipConfig.PublicIpAddress.Id
                                
                                if (-not $publicIpId) {
                                    Write-Verbose "Skipping null Public IP ID for VM: $resourceName"
                                    continue
                                }
                                
                                # Get the public IP address details - parse the resource ID
                                try {
                                    if ($publicIpId -match "/resourceGroups/([^/]+)/providers/Microsoft.Network/publicIPAddresses/([^/]+)") {
                                        $pipRg = $Matches[1]
                                        $pipName = $Matches[2]
                                        $publicIp = Get-AzPublicIpAddress -ResourceGroupName $pipRg -Name $pipName
                                    } else {
                                        Write-Warning "Could not parse Public IP ID: $publicIpId"
                                        continue
                                    }
                                    
                                    if ($publicIp -and $publicIp.IpAddress -ne "Dynamic" -and $publicIp.IpAddress -ne $null) {
                                        $findings += [PSCustomObject]@{
                                            ResourceGroup = $resourceGroup
                                            ResourceName = $resourceName
                                            Endpoint = $publicIp.IpAddress
                                            Type = "Public IP"
                                        }
                                        
                                        # If the VM has a DNS name, add it as well
                                        if ($publicIp.DnsSettings -and $publicIp.DnsSettings.Fqdn) {
                                            $findings += [PSCustomObject]@{
                                                ResourceGroup = $resourceGroup
                                                ResourceName = $resourceName
                                                Endpoint = $publicIp.DnsSettings.Fqdn
                                                Type = "FQDN"
                                            }
                                        }
                                    }
                                } catch {
                                    Write-Warning "Error processing Public IP for VM $resourceName`: $_"
                                }
                            }
                        }
                    }
                } catch {
                    Write-Warning "Error processing NIC for VM $resourceName`: $_"
                }
            }
        }
    }
    catch {
        Write-Error "Error processing Virtual Machines: $_"
    }
    
    return $findings
}

Export-ModuleMember -Function Get-VirtualMachinesEndpoints
