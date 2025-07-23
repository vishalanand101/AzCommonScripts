Install-Module -Name "Microsoft.Graph.Authentication" -AllowClobber -Force
install-Module -Name "Microsoft.Graph.Applications" -AllowClobber -Force   

$tenantId = ""
$appId = ""
$secret = ""

$securePassword = ConvertTo-SecureString $secret -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $appId, $securePassword

Connect-AzAccount -ServicePrincipal -Credential $credential -Tenant $tenantId
Connect-MgGraph -Scopes 'Application.Read.All' 


$SecuredPasswordPassword = ConvertTo-SecureString -String $SecuredPassword -AsPlainText -Force

$ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ApplicationId, $SecuredPasswordPassword
Connect-MgGraph -TenantId $tenantID -ClientSecretCredential $ClientSecretCredential

Get-MgApplication | Select-Object DisplayName, AppId, @{Name="SecretExpiry"; Expression={($_.PasswordCredentials | Sort-Object EndDateTime -Descending | Select-Object -First 1).EndDateTime}} | Format-Table -AutoSize
