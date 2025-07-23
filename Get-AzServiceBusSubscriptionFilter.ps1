Login-azaccount
$token = (Get-AzAccessToken).Token
$subscriptionobject = @()
$headers = @{
    "Content-Type" = "application/json"
    "Authorization"= "Bearer $token"
}
$servicebuses = Get-AzServiceBusNamespace
#for queue
#$queue = Invoke-restmethod -Uri "https://management.azure.com$/queues?api-version=2017-04-01" -Method Get -Headers $headers

# for topics
foreach($servicebus in $servicebuses){
    $topics = Invoke-restmethod -Uri "https://management.azure.com$($servicebus.Id)/topics?api-version=2017-04-01" -Method Get -Headers $headers
    if($topics){
        $topicsname = $topics.value.name
    }
    if($topicsname){
        foreach ($topic  in $topicsname) {
            $uri = "https://management.azure.com$($servicebus.Id)/topics/$topic/subscriptions?api-version=2024-01-01" 
            $subscription = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers 
            $subscriptions = $subscription.value.name
            if($subscriptions){
                foreach ($subscription  in $subscriptions ) {
                    $uri = "https://management.azure.com$($servicebus.Id)/topics/$topic/subscriptions/$($subscription)/rules?api-version=2024-01-01"
                    $subsfilter = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
                    $tempfilters=$subsfilter.value.properties
            
                }
                if($tempfilters){
                    foreach ($tempfilter in $tempfilters) {
                        $subscriptionobject += [PSCustomObject]@{
                            ServiceBusName = $servicebus.Name
                            TopicName = $topic
                            SubscriptiName = $subscription
                            filterType = $tempfilter.filterType
                            $tempfilter.filterType = $tempfilter.($tempfilter.filterType).sqlExpression
            
            
                        }
                    }
                }
                
                
            }
            
        }
    }
    Write-Host "Retrieved for $($servicebus.Name)"

}
