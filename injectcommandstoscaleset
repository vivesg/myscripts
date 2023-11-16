#educational purposes
#no warranty
#developed by GEVIVESH

$subscriptionid = "AAAA-BBB-CCCC"
$ResourceGroup = "RGNAME"
$VMSSName = "VMSS"
$location = "AZUREREGION"
$SCRIPT = "ipconfig"


$token = (Get-AzAccessToken).Token   # We are using Azure Powershell module to get the Token you can get it from another place ;)

#creating the header 
$authHeader = @{
  'Authorization' = 'Bearer ' + $token
  'Content-Type'  = 'application/json'
}


$restUri = "https://management.azure.com/subscriptions/" +$subscriptionid+"/resourceGroups/" +$ResourceGroup + "/providers/Microsoft.Compute/virtualMachineScaleSets/" + $VMSSName + "/virtualMachines?api-version=2023-07-01"


$body = ($requestbody | ConvertTo-Json) 
$response = Invoke-RestMethod -Uri $restUri -Method Get -Headers $authHeader

#----------------------------------------

$table =  @()


$COMMANDNAME = "hostname"


foreach($instance in $response.value){
    $res = New-Object -TypeName psobject
    $res | Add-Member -MemberType NoteProperty -Name PlatFormName -Value $instance.name -Force
    $restUri = "https://management.azure.com"  + "/subscriptions/" + $subscriptionid + "/resourceGroups/" + $ResourceGroup + "/providers/Microsoft.Compute/virtualMachines/" + $instance.name  +  "?api-version=2023-07-01"
    $body = ($requestbody | ConvertTo-Json) 
    $response = Invoke-RestMethod -Uri $restUri -Method Get -Headers $authHeader
    $ComputerName = $response.properties.osProfile.computerName
    $res | Add-Member -MemberType NoteProperty -Name Name -Value $Computername -Force
    $table += $res


    $restUri = "https://management.azure.com/subscriptions/" + $subscriptionid  + '/resourceGroups/' +  $ResourceGroup  + "/providers/Microsoft.Compute/virtualMachines/" + $instance.name + '/runCommands/' + $COMMANDNAME + '?api-version=2021-07-01'

    $requestbody = @{
      "location"   = $location
      "properties" = @{
        "source" = @{
          "script" = $SCRIPT
        }
      }
    }

    $body = ($requestbody | ConvertTo-Json) 
    $response = Invoke-RestMethod -Uri $restUri -Method Put -Headers $authHeader -Body $body


    # QUERY THE RESPONSE
    $restUri = 'https://management.azure.com/subscriptions/' + $subscriptionid + '/resourceGroups/' +  $ResourceGroup  + '/providers/Microsoft.Compute/virtualMachines/' +  $instance.name +  '/runCommands/' + $COMMANDNAME + '?$expand=instanceView&api-version=2023-07-01'
    $response = Invoke-RestMethod -Uri $restUri -Method Get -Headers $authHeader
   

    $res | Add-Member -MemberType NoteProperty -Name Comando -Value  $response.properties.instanceView.output   -Force




}

$table | FT

