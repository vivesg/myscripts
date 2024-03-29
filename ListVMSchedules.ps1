#author gevivesh
# THE SCRIPT SOFTWARE IS PROVIDED "AS IS" and For educational purposes
# GET ALL THE VMS ON THE SUB THAT HAVE THE AUTOSHUTDOWN OPTION Setup Enabled/Disabled


Connect-AzAccount 

#Set the Subscription please use the SubId
Set-AzContext -Subscription "xxxxx-xxxxx-xxxxx-xxxxx-"

$Schedules = Get-AzResource -ResourceType "microsoft.devtestlab/schedules"

# Now We need to check what of the schedules are enabled and what are the VMs affected by this schedules


#We create a list for the report
$Results = New-Object System.Collections.ArrayList

foreach($schedule in $Schedules){
    $currentSchedule = Get-AzResource -ResourceId $schedule.ResourceId  # Get the schedule properties
    $obj = New-Object -TypeName psobject
    $obj | Add-Member -MemberType NoteProperty -Name VMID -Value $currentSchedule.Properties.targetResourceId   # Get VMID
    $obj | Add-Member -MemberType NoteProperty -Name Time -Value $currentSchedule.Properties.dailyRecurrence.time  #GET THE SCHEDULE Time 
    $obj | Add-Member -MemberType NoteProperty -Name TimeZone -Value $currentSchedule.Properties.timeZoneId # get the timezone
    $obj | Add-Member -MemberType NoteProperty -Name IsEnabled -Value $currentSchedule.Properties.status  # get if the schedule is enabled or disabled
    $name = $currentSchedule.Properties.targetResourceId.Split("/")   # split the resource id to get the RG and Name

    $obj | Add-Member -MemberType NoteProperty -Name RGName -Value $name[-5]  
    $obj | Add-Member -MemberType NoteProperty -Name VMName -Value $name[-1]
    [void]$results.Add($obj) 
}

$Results | Fl
$Results | Export-Csv ReportSchedules.csv
$location = Get-Location 
Write-Host "The Report has been generated on " $location"\ReportSchedules.csv"
