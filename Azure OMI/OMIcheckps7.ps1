#POWERSHELL 7.1 Required

#run like .\OMIcheckps7.ps1 -subid "AAAAA-BBBB-CCCC-DDD"

Param
(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $subid,
    [Parameter(Mandatory = $true, Position = 1)]
    [string] $filename
)

Start-Transcript -Path ($filename + ".txt")
Set-AzContext -Subscription $subid
Write-Output "SubID :" $subid
Write-Output "Listing Virutal Machines in subscription " ((Get-AzContext).Subscription.Name)
$VMs = Get-AzVM -Status
$VMsSorted = $VMs | Sort-Object -Property ResourceGroupName
$results = $VMs | ForEach-Object -Parallel {
    $res = New-Object -TypeName psobject
    $upgradeOMI = $false; #detect only
    $checkScriptPath = "omi_check.sh"
    $upgradeScriptPath = "omi_upgrade_v2.sh"     
    $VM = $_ 
            
    $vm_status = Get-AZVM -Name $VM.Name -ResourceGroupName $VM.ResourceGroupName -Status
    $res | Add-Member -MemberType NoteProperty -Name ID -Value $VM.Id
    $res | Add-Member -MemberType NoteProperty -Name Name -Value $VM.Name
    $res | Add-Member -MemberType NoteProperty -Name ResourceGroupName -Value $VM.ResourceGroupName
    if ($VM.PowerState -ne "VM running") {
               
        Write-Host -ForegroundColor Gray `t`t  "RG:" $VM.ResourceGroupName "," "VMName" $VM.Name  ",VM is not running"
        $res | Add-Member -MemberType NoteProperty -Name Status -Value "VM Not Running"
        $res 
        continue
    }

    if ($VM.StorageProfile.OsDisk.OsType.ToString() -ne "Linux") {
        Write-Host -ForegroundColor Gray `t`t  "RG:" $VM.ResourceGroupName "," "VMName" $VM.Name ",VM is not running Linux OS"
        $res | Add-Member -MemberType NoteProperty -Name Status -Value "Windows VM"
        $res 
        continue
    }

    if ( $vm_status.VMAgent.Statuses.DisplayStatus -ne "Ready") {
        Write-Host -ForegroundColor Gray `t`t  "RG:" $VM.ResourceGroupName "," "VMName" $VM.Name   ",Agent it is not in ready"
        $res | Add-Member -MemberType NoteProperty -Name Status -Value "Agent Not Ready"
        $res 
        continue 
    }
           
    # TODO: Consider setting timeout. Parameter does not exist, -AsJob is an option for v2.
    $check = Invoke-AzVMRunCommand -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name -CommandId 'RunShellScript' -ScriptPath $checkScriptPath

    $split = $check.Value.Message.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)
    if ($check.Value.Message.Contains("/opt/omi/bin/omiserver:")) {
        $pkgVer = $split[3]
        if ($pkgVer -eq "OMI-1.6.8-1") {
                  
            Write-Host -ForegroundColor Green `t`t  "RG:" $VM.ResourceGroupName "," "VMName" $VM.Name  ",VM has patched OMI version " $pkgVer
            $res | Add-Member -MemberType NoteProperty -Name Status -Value "OMI Patched"
        }
        else {
            Write-Host -ForegroundColor Red `t`t  "RG:" $VM.ResourceGroupName "," "VMName" $VM.Name  ",VM has vulnerable OMI version " $pkgVer
            $res | Add-Member -MemberType NoteProperty -Name Status -Value "OMI Vulnerable" 
            $res | Add-Member -MemberType NoteProperty -Name OMIVersion -Value $pkgVer
            if ($upgradeOMI) {
                $upgrade = Invoke-AzVMRunCommand -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name -CommandId 'RunShellScript' -ScriptPath $upgradeScriptPath
                Write-Host -ForegroundColor Red `t`t   "RG:" $VM.ResourceGroupName "," "VMName" $VM.Name  ",Result of OMI package upgrade attempt: " $upgrade.Value.Message
            }
        }
    }
    else {
               
        Write-Host -ForegroundColor Gray `t`t  "RG:" $VM.ResourceGroupName "," "VMName" $VM.Name   ",VM has no OMI package"
        $res | Add-Member -MemberType NoteProperty -Name Status -Value "NO OMI Installed" 
    } 
  
} 
$results | Export-Csv ($filename + ".csv")
Write-Host "2 File has been generated " $filename ", Process has finished for this subscription"
