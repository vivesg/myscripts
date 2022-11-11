# GET ALL THE VMS ON THE SUB THAT HAVE THE AUTOSHUTDOWN OPTION ENABLED


#Connect-AzAccount 

#Set the Subscription please use the SubId
Set-AzContext -Subscription "33ff68b5-192b-4438-b2d5-c8b925dc9f6f"

$Schedules = Get-AzResource -ResourceType "microsoft.devtestlab/schedules"

# Now We need to check what of the schedules are enabled and what are the VMs affected by this schedules


#We create a list for the report
$Results = New-Object System.Collections.ArrayList

foreach($schedule in $Schedules){
    $currentSchedule = Get-AzResource -ResourceId $schedule.ResourceId  # Get the schedules
    $obj = New-Object -TypeName psobject
    $obj | Add-Member -MemberType NoteProperty -Name VMID -Value $currentSchedule.Properties.targetResourceId   # Get VMID
    $obj | Add-Member -MemberType NoteProperty -Name Time -Value $currentSchedule.Properties.dailyRecurrence.time 
    $obj | Add-Member -MemberType NoteProperty -Name TimeZone -Value $currentSchedule.Properties.timeZoneId
    $obj | Add-Member -MemberType NoteProperty -Name IsEnabled -Value $currentSchedule.Properties.status
    $name = $currentSchedule.Properties.targetResourceId.Split("/") 

    $obj | Add-Member -MemberType NoteProperty -Name RGName -Value $name[-5]
    $obj | Add-Member -MemberType NoteProperty -Name VMName -Value $name[-1]
    [void]$results.Add($obj) 
}

$Results | Fl
$Results | Export-Csv ReportSchedules.csv
$location = Get-Location 
Write-Host "The Report has been generated on " $location"\ReportSchedules.csv"