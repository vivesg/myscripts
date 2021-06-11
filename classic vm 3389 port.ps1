#Please make sure to install the following 
# ref https://docs.microsoft.com/en-us/powershell/azure/servicemanagement/install-azure-ps?view=azuresmps-4.0.0
#install running on Powershell as administrator
# Install-Module Azure

#Make sure you are Classic administrator on The subscription (check administrator permissions on subscription)

#authenticate 
Add-AzureAccount

#then run the following
Clear
#---------------------
Write-Host "Checking for LocalPort 3389 Endpoints"
$vms = Get-AzureVM
foreach ($vm in $vms) {
    Write-Host "----------+++-----------"
    $endpoints = Get-AzureEndPoint -VM $VM
    
    foreach($endpoint in $endpoints){   

    if ($endpoint.LocalPort -eq 3389) {
        $acl = AzureAclConfig -EndpointName $endpoint.Name -VM $vm
        Write-Host "VM NAME:"  $vm.Name
       
        if ($endpoint.Acl -ne "") {
            Write-Host "ACL :" $endpoint.Acl
           
        }
        else {
            Write-Host "Potentially found Port allow everything for Port 3389"  
        }
        $acl 
    }
    }
}