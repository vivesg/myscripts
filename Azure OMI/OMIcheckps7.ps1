#POWERSHELL 7.1 Required

#run like .\OMIcheckps7.ps1 -subid "AAAAA-BBBB-CCCC-DDD"

$subs = Get-AzSubscription

Param
(
     [Parameter(Mandatory=$true, Position=0)]
     [string] $subid
)

    Set-AzContext -Subscription $subid
    Write-Output "Listing Virutal Machines in subscription '$($sub.Name)'"
    $VMs = Get-AzVM -Status
    $VMsSorted = $VMs | Sort-Object -Property ResourceGroupName
    $VMs | ForEach-Object -Parallel {
            
        $upgradeOMI = $false; #detect only
        $checkScriptPath = "omi_check.sh"
        $upgradeScriptPath = "omi_upgrade.sh"
            

        $VM = $_ 
            
        $vm_status = Get-AZVM -Name $VM.Name -ResourceGroupName $VM.ResourceGroupName -Status
      
        if ($VM.PowerState -ne "VM running") {
               
            Write-Host -ForegroundColor Gray `t`t  "RG: " $VM.ResourceGroupName "|||" "VMName" $VM.Name  ": VM is not running"
            continue
        }

        if ($VM.StorageProfile.OsDisk.OsType.ToString() -ne "Linux") {
            Write-Host -ForegroundColor Gray `t`t  "RG: " $VM.ResourceGroupName "|||" "VMName" $VM.Name  ": VM is not running Linux OS"
            continue
        }

        if ( $vm_status.VMAgent.Statuses.DisplayStatus -ne "Ready") {
            Write-Host -ForegroundColor Yellow `t`t  "RG: " $VM.ResourceGroupName "|||" "VMName" $VM.Name  ": Agent it is not in ready"
            continue 
        }
           
        # TODO: Consider setting timeout. Parameter does not exist, -AsJob is an option for v2.
        $check = Invoke-AzVMRunCommand -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name -CommandId 'RunShellScript' -ScriptPath $checkScriptPath

        $split = $check.Value.Message.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)
        if ($check.Value.Message.Contains("/opt/omi/bin/omiserver:")) {
            $pkgVer = $split[3]
            if ($pkgVer -eq "OMI-1.6.8-1") {
                  
                Write-Host -ForegroundColor Green `t`t  "RG: " $VM.ResourceGroupName "|||" "VMName" $VM.Name  ": VM has patched OMI version " $pkgVer
            }
            else {
                Write-Host "RG: " $VM.ResourceGroupName 
                Write-Host -ForegroundColor Red `t`t  "RG: " $VM.ResourceGroupName "|||" "VMName" $VM.Name  ": VM has vulnerable OMI version " $pkgVer
                if ($upgradeOMI) {
                    $upgrade = Invoke-AzVMRunCommand -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name -CommandId 'RunShellScript' -ScriptPath $upgradeScriptPath
                    Write-Host -ForegroundColor Red `t`t   "RG: " $VM.ResourceGroupName "|||" "VMName" $VM.Name  ": Result of OMI package upgrade attempt: " $upgrade.Value.Message
                }
            }
        }
        else {
               
            Write-Host -ForegroundColor Gray `t`t  "RG: " $VM.ResourceGroupName "|||" "VMName" $VM.Name   ": VM has no OMI package"
        }
    }

