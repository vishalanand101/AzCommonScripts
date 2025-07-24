$token = (Get-AzAccessToken).Token

$subscriptionId = ""
$resourceGroup = ""
$apimServiceName = ""

$ApiMgmtContext = New-AzApiManagementContext -ResourceGroupName $resourceGroup -ServiceName $apimname
$apis=Get-AzApiManagementApi -Context $ApiMgmtContext
$apiIds = $apis.ApiId

#for non throttling
$uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.ApiManagement/service/$apimServiceName/apis/$apiId/operations?api-version=2024-05-01"
$response = Invoke-RestMethod -Method GET -Uri $uri -Headers @{ Authorization = "Bearer $token" }
$response.value.properties.urlTemplate

# for throttling
$apioperation=Get-AzApiManagementOperation -Context $ApiMgmtContext -ApiId $apiIds[0]
$apioperation.UrlTemplate

# donwload the api_spec.json file now
$content = Get-Content -Path "$path/api_spec.json" -Raw|ConvertFrom-Json -AsHashtable
$content.paths

# Now validate
Write-Host $apioperation.UrlTemplate
Write-Host $content.path
