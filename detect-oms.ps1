Param
(
     [Parameter(Mandatory=$true, Position=0)]
     [string] $subid,
     [Parameter(Mandatory=$true, Position=1)]
     [string] $csvfile
)

Set-AzContext -Subscription $subid
$subid = ((Get-AzContext).Subscription.Id)
Write-Output "Subscription ID:" ((Get-AzContext).Subscription.Id)
az account set --subscription $subid
$vms = get-azvm
$extensions = 0
$outputvms =  New-Object System.Collections.ArrayList
foreach ($vm in $vms) {
    if ($vm.StorageProfile.OsDisk.OsType -eq "Linux") {
        $obj = New-Object -TypeName psobject
        $jsonoutput = az vm show -g $vm.ResourceGroupName -n $vm.Name --query 'resources' -o json
        $vm_status = Get-AZVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Status
        $guest_agent_status = $vm_status.VMAgent.Statuses
        $extensions = $jsonoutput | Convertfrom-Json
        $extoms = $null
        $extomsinfo = $null
        foreach ($ext in $extensions) {
           if($ext.Name -eq "OmsAgentForLinux"){
            $extoms = $ext 
           }
        }
        foreach ($ext in $vm_status.Extensions) {
            if($ext.Name -eq "OmsAgentForLinux"){
                $extomsinfo = $ext 
            }
        }
        $obj | Add-Member -MemberType NoteProperty -Name SubID -Value $subid
        $obj | Add-Member -MemberType NoteProperty -Name ID -Value  $vm.id 
        $obj | Add-Member -MemberType NoteProperty -Name VMName -Value  $vm.Name 
        $obj | Add-Member -MemberType NoteProperty -Name AgentStatus -Value  $guest_agent_status.DisplayStatus
        $obj | Add-Member -MemberType NoteProperty -Name Extension -Value  $extoms.name 
        $obj | Add-Member -MemberType NoteProperty -Name ExtensionVersion -Value $extomsinfo.typeHandlerVersion 
        $obj | Add-Member -MemberType NoteProperty -Name enableAutomaticUpgrade -Value   $extoms.enableAutomaticUpgrade
        $obj | Add-Member -MemberType NoteProperty -Name enableAutomaticUpgradeMinor -Value   $extoms.autoUpgradeMinorVersion
        $obj | Add-Member -MemberType NoteProperty -Name StatusJson -Value   ($extoms | ConvertTo-Json) 
        [void]$outputvms.Add($obj) 
    }
    
} 
$outputvms | Export-Csv ($csvfile + ".csv")
