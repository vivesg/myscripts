#Developed by GEVIVESH
#Use by your own risk 
#Educational Purposes

$subscriptionid = "ABCD-ADDSAD-DSADD-FFFF"
$ResourceGroup = "RGNAME"
$VMSSName = "VMSS"


$token = (Get-AzAccessToken).Token   # We are using Azure Powershell module to get the Token you can get it from another place ;)

#creating the header 
$authHeader = @{
  'Authorization' = 'Bearer ' + $token
  'Content-Type'  = 'application/json'
}


$restUri = "https://management.azure.com/subscriptions/" +$subscriptionid+"/resourceGroups/" +$ResourceGroup + "/providers/Microsoft.Compute/virtualMachineScaleSets/" + $VMSSName + "/virtualMachines?api-version=2023-07-01"


$body = ($requestbody | ConvertTo-Json) 
$response = Invoke-RestMethod -Uri $restUri -Method Get -Headers $authHeader -Body $body

#----------------------------------------

$table =  @()

foreach($instance in $response.value){
    $res = New-Object -TypeName psobject
    $res | Add-Member -MemberType NoteProperty -Name PlatFormName -Value $instance.name -Force
    $restUri = "https://management.azure.com"  + "/subscriptions/" + $subscriptionid + "/resourceGroups/" + $ResourceGroup + "/providers/Microsoft.Compute/virtualMachines/" + $instance.name  +  "?api-version=2023-07-01"
    $body = ($requestbody | ConvertTo-Json) 
    $response = Invoke-RestMethod -Uri $restUri -Method Get -Headers $authHeader -Body $body
    $ComputerName = $response.properties.osProfile.computerName
    $res | Add-Member -MemberType NoteProperty -Name Name -Value $Computername -Force
    $table += $res
}

$table | FT

