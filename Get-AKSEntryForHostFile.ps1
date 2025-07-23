$host=@()
function Get-PvtIpAddress {
    param (
        [Parameter(Mandatory = $true)]
        [string]$uri,

        [Parameter(Mandatory = $true)]
        [string]$token
    )

    $headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer $token"
    }

    $detail = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers

    return $detail.properties.ipConfigurations.properties.privateIPAddress
}
Login-azaccount 
$subscriptionsid = (Get-AzSubscription).Id
foreach ($subscriptionId in $subscriptionsId) {
    set-azcontext $subscriptionId
    $aksclusters = Get-AzAksCluster
    if($aksclusters){
        $token = (Get-AzAccessToken).Token
    }           
    
    foreach ($akscluster in $aksclusters) {
        $ManagedRG = $akscluster.NodeResourceGroup
        $PrivateFQDN = $akscluster.PrivateFQDN
        $pvepdetail = Get-AzPrivateendpoint -ResourceGroupName $ManagedRG
        $networkinterfaces = $pvepdetail.NetworkInterfaces.Id
        foreach ($networkinterface in $networkinterfaces) {
            $uri = "https://management.azure.com$($networkinterface)?api-version=2024-01-01"
            $ipaddress = Get-PvtIpAddress -Uri $uri -token $token
            if($ipaddress){
                $host +=[PSCustomObject]@{
                    IPAddress = $ipaddress
                    HostName = $PrivateFQDN
                    
                }
            }
            
        }
    }
}

