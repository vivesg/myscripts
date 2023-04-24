$SUBID = "FFFF-FFFF-FFFF-FFF-FFF"
Connect-AzAccount 
Set-AzContext -Subscription $SUBID
$ENDPOINT = "https://management.azure.com/subscriptions/" + $SUBID + "/providers/Microsoft.Compute/virtualMachines?api-version=2022-11-01&statusOnly=true"
$token = (Get-AzAccessToken).Token

#creating the header 
$authHeader = @{
    'Authorization' = 'Bearer ' + $token
    'Content-Type'  = 'application/json'
}

Write-Host "Trying API Method"
Measure-Command {
    $response = Invoke-RestMethod -Uri $ENDPOINT  -Method GET -Headers $authHeader 
    $vms = $response.value
    foreach ($vm in $vms) {
        Write-Host $VM.Name  ": STATUS  -->  "  $vm.properties.instanceView.Statuses[1].code 
    }
}

Write-Host "Trying Powershell AZ Module"
Measure-Command { Get-AzVM -Status }
