#Author gevivesh@microsoft.com
# How to Run commands and check the output on Azure Virtual Machine
# Example using the Azure REST API
# Example as-is please run this as your own risk
# I Used POST and GET to REST API to run commands
# https://learn.microsoft.com/en-us/rest/api/compute/virtual-machines/run-command?tabs=HTTP

# Login to Azure 
Connect-AzAccount 

#declare the variables
$VMNAME = "VMNAME"
$RGNAME = "RGNAME"
$COMMANDNAME = "COMMANDNAME"
$SCRIPT = "ipconfig"   # this is the command that we are going to run

$token = (Get-AzAccessToken).Token   # We are using Azure Powershell module to get the Token you can get it from another place ;)

$location = "eastus2" # please add the region of where the VM is located
$subid = "ffff-xxxx-ffff-1111-subid" #add the sub id


#creating the header 
$authHeader = @{
  'Authorization' = 'Bearer ' + $token
  'Content-Type'  = 'application/json'
}

# SENDING THE COMMAND (AZURE RUN COMMAND) 

$restUri = "https://management.azure.com/subscriptions/" + $subid + '/resourceGroups/' + $RGNAME + '/providers/Microsoft.Compute/virtualMachines/' + $VMNAME + '/runCommands/' + $COMMANDNAME + '?api-version=2021-07-01'

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
$restUri = 'https://management.azure.com/subscriptions/' + $subid + '/resourceGroups/' + $RGNAME + '/providers/Microsoft.Compute/virtualMachines/' + $VMNAME + '/runCommands/' + $COMMANDNAME + '?$expand=instanceView&api-version=2022-08-01'
$response = Invoke-RestMethod -Uri $restUri -Method Get -Headers $authHeader
$response = $response | ConvertFrom-Json
$response.properties.instanceView
