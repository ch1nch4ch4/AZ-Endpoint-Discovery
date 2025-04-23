<#
.SYNOPSIS
    Discovers messaging services with externally accessible endpoints.

.DESCRIPTION
    This module identifies Azure messaging services like Service Bus, Event Hubs,
    and Event Grid and extracts their endpoint information.

.NOTES
    Author: liarm
    Date: April 20, 2025
#>

function Get-ServiceBusEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all Service Bus namespaces in the current subscription using Resource Manager API
        $serviceBusNamespaces = Get-AzResource -ResourceType "Microsoft.ServiceBus/namespaces" -ErrorAction SilentlyContinue
        
        if (-not $serviceBusNamespaces) {
            Write-Verbose "No Service Bus namespaces found in the current subscription."
            return $findings
        }
        
        foreach ($namespace in $serviceBusNamespaces) {
            $resourceGroup = $namespace.ResourceGroupName
            $resourceName = $namespace.Name
            
            Write-Verbose "Processing Service Bus namespace: $($resourceName) in $($resourceGroup)"
            
            # Get namespace details using Resource Manager API
            $namespaceDetails = Get-AzResource -ResourceGroupName $resourceGroup -ResourceType "Microsoft.ServiceBus/namespaces" -Name $resourceName -ExpandProperties -ErrorAction SilentlyContinue
            
            if ($namespaceDetails) {
                # Add the namespace endpoint
                $endpoint = "$($resourceName).servicebus.windows.net"
                
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $endpoint
                    Type = "Service Bus Namespace"
                }
                
                # Check for public network access
                $publicNetworkAccess = $namespaceDetails.Properties.publicNetworkAccess
                
                if ($publicNetworkAccess -eq "Enabled" -or $publicNetworkAccess -eq $null) {
                    $findings += [PSCustomObject]@{
                        ResourceGroup = $resourceGroup
                        ResourceName = $resourceName
                        Endpoint = "Public Access Enabled"
                        Type = "Service Bus Network Access"
                    }
                }
                
                # Check for private endpoints
                if ($namespaceDetails.Properties.privateEndpointConnections) {
                    foreach ($connection in $namespaceDetails.Properties.privateEndpointConnections) {
                        if ($connection.properties.privateLinkServiceConnectionState.status -eq "Approved") {
                            $findings += [PSCustomObject]@{
                                ResourceGroup = $resourceGroup
                                ResourceName = $resourceName
                                Endpoint = $connection.properties.privateEndpoint.id
                                Type = "Service Bus Private Endpoint"
                            }
                        }
                    }
                }
                
                # Get queues
                try {
                    $queues = Get-AzResource -ResourceGroupName $resourceGroup -ResourceType "Microsoft.ServiceBus/namespaces/queues" -ParentResource "namespaces/$resourceName" -ErrorAction SilentlyContinue
                    
                    foreach ($queue in $queues) {
                        $queueName = $queue.Name
                        
                        $findings += [PSCustomObject]@{
                            ResourceGroup = $resourceGroup
                            ResourceName = "$($resourceName)/$($queueName)"
                            Endpoint = "$($endpoint)/$($queueName)"
                            Type = "Service Bus Queue"
                        }
                    }
                }
                catch {
                    Write-Verbose "Error getting queues for Service Bus namespace $($resourceName): $($_)"
                }
                
                # Get topics
                try {
                    $topics = Get-AzResource -ResourceGroupName $resourceGroup -ResourceType "Microsoft.ServiceBus/namespaces/topics" -ParentResource "namespaces/$resourceName" -ErrorAction SilentlyContinue
                    
                    foreach ($topic in $topics) {
                        $topicName = $topic.Name
                        
                        $findings += [PSCustomObject]@{
                            ResourceGroup = $resourceGroup
                            ResourceName = "$($resourceName)/$($topicName)"
                            Endpoint = "$($endpoint)/$($topicName)"
                            Type = "Service Bus Topic"
                        }
                        
                        # Get subscriptions for this topic
                        try {
                            $subscriptions = Get-AzResource -ResourceGroupName $resourceGroup -ResourceType "Microsoft.ServiceBus/namespaces/topics/subscriptions" -ParentResource "namespaces/$resourceName/topics/$topicName" -ErrorAction SilentlyContinue
                            
                            foreach ($subscription in $subscriptions) {
                                $subscriptionName = $subscription.Name
                                
                                $findings += [PSCustomObject]@{
                                    ResourceGroup = $resourceGroup
                                    ResourceName = "$($resourceName)/$($topicName)/$($subscriptionName)"
                                    Endpoint = "$($endpoint)/$($topicName)/subscriptions/$($subscriptionName)"
                                    Type = "Service Bus Subscription"
                                }
                            }
                        }
                        catch {
                            Write-Verbose "Error getting subscriptions for topic $($topicName) in Service Bus namespace $($resourceName): $($_)"
                        }
                    }
                }
                catch {
                    Write-Verbose "Error getting topics for Service Bus namespace $($resourceName): $($_)"
                }
            }
        }
    }
    catch {
        Write-Error "Error processing Service Bus: $($_)"
    }
    
    return $findings
}

function Get-EventHubsEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all Event Hub namespaces in the current subscription
        $eventHubNamespaces = Get-AzEventHubNamespace
        
        foreach ($namespace in $eventHubNamespaces) {
            $resourceGroup = $namespace.ResourceGroupName
            $resourceName = $namespace.Name
            
            Write-Verbose "Processing Event Hub Namespace: $resourceName in $resourceGroup"
            
            # Get the service bus endpoint
            $endpoint = $namespace.ServiceBusEndpoint
            
            if ($endpoint) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $endpoint
                    Type = "Event Hub Endpoint"
                }
            }
            
            # Check if public network access is enabled
            if ($namespace.PublicNetworkAccess -eq "Enabled") {
                $findings | Where-Object { $_.ResourceName -eq $resourceName } | ForEach-Object {
                    $_.Type = "$($_.Type) (Public Access)"
                }
                
                # Check for IP rules
                $networkRuleSets = Get-AzEventHubNetworkRuleSet -ResourceGroupName $resourceGroup -Namespace $resourceName
                
                if ($networkRuleSets -and $networkRuleSets.IpRules -and $networkRuleSets.IpRules.Count -gt 0) {
                    foreach ($ipRule in $networkRuleSets.IpRules) {
                        $findings += [PSCustomObject]@{
                            ResourceGroup = $resourceGroup
                            ResourceName = $resourceName
                            Endpoint = $ipRule.IpMask
                            Type = "Allowed IP Range"
                        }
                    }
                }
                elseif ($networkRuleSets -and $networkRuleSets.DefaultAction -eq "Allow") {
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
            
            # Get the event hubs
            $eventHubs = Get-AzEventHub -ResourceGroupName $resourceGroup -Namespace $resourceName
            
            foreach ($eventHub in $eventHubs) {
                $eventHubName = $eventHub.Name
                
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = "$resourceName/$eventHubName"
                    Endpoint = "$endpoint/$eventHubName"
                    Type = "Event Hub"
                }
            }
        }
    }
    catch {
        Write-Error "Error processing Event Hubs: $_"
    }
    
    return $findings
}

function Get-EventGridEndpoints {
    [CmdletBinding()]
    param()
    
    $findings = @()
    
    try {
        # Get all Event Grid domains in the current subscription
        $eventGridDomains = Get-AzEventGridDomain
        
        foreach ($domain in $eventGridDomains) {
            $resourceGroup = $domain.ResourceGroupName
            $resourceName = $domain.Name
            
            Write-Verbose "Processing Event Grid Domain: $resourceName in $resourceGroup"
            
            # Get the endpoint
            $endpoint = $domain.Endpoint
            
            if ($endpoint) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $endpoint
                    Type = "Event Grid Domain Endpoint"
                }
            }
            
            # Check for public network access
            if ($domain.PublicNetworkAccess -eq "Enabled") {
                $findings | Where-Object { $_.ResourceName -eq $resourceName } | ForEach-Object {
                    $_.Type = "$($_.Type) (Public Access)"
                }
            }
            else {
                $findings | Where-Object { $_.ResourceName -eq $resourceName } | ForEach-Object {
                    $_.Type = "$($_.Type) (Private Access)"
                }
            }
        }
        
        # Get all Event Grid topics in the current subscription
        $eventGridTopics = Get-AzEventGridTopic
        
        foreach ($topic in $eventGridTopics) {
            $resourceGroup = $topic.ResourceGroupName
            $resourceName = $topic.Name
            
            Write-Verbose "Processing Event Grid Topic: $resourceName in $resourceGroup"
            
            # Get the endpoint
            $endpoint = $topic.Endpoint
            
            if ($endpoint) {
                $findings += [PSCustomObject]@{
                    ResourceGroup = $resourceGroup
                    ResourceName = $resourceName
                    Endpoint = $endpoint
                    Type = "Event Grid Topic Endpoint"
                }
            }
            
            # Check for public network access
            if ($topic.PublicNetworkAccess -eq "Enabled") {
                $findings | Where-Object { $_.ResourceName -eq $resourceName } | ForEach-Object {
                    $_.Type = "$($_.Type) (Public Access)"
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
        Write-Error "Error processing Event Grid: $_"
    }
    
    return $findings
}

Export-ModuleMember -Function Get-ServiceBusEndpoints, Get-EventHubsEndpoints, Get-EventGridEndpoints
