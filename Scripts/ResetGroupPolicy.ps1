#Region: Reset Group Policy
If (Test-ComputerSecureChannel) {
    Remove-Item -Path "$env:WINDIR\System32\GroupPolicy\gpt.ini" -Force -Confirm:$false
    Remove-Item -Path "$env:WINDIR\System32\GroupPolicy\Machine\Registry.pol" -Force -Confirm:$false
    # Purge Kerberos tickets and update Group Policy
    & $env:WINDIR\System32\klist.exe -lh 0 -li 0x3e7 purge
    & $env:WINDIR\System32\gpupdate.exe /force /target:computer /wait:0
    & $env:WINDIR\System32\gpupdate.exe /force /target:user /wait:0
} Else {    
    # No connectivity to the domain so do nothing
}
#EndRegion
#Region: Restart SMS Agent Host
If (Test-ComputerSecureChannel) {
    # Create a scheduled task to restart the SMS Agent Host service in 5 minutes
    $ScheduledTaskActions = New-ScheduledTaskAction -Execute "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument '-ExecutionPolicy bypass -Command "Get-Service -Name CcmExec | Restart-Service -Force -Verbose"'
    $ScheduledTaskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5)
    $ScheduledTask = Register-ScheduledTask -TaskName "Restart SMS Agent Host" -Description "Task will restart the SMS Agent Host service, then delete itself" -Action $ScheduledTaskActions -Trigger $ScheduledTaskTrigger -User "NT AUTHORITY\System"
    # Edit the conditions of the task to allow it to run on batteries
    $ScheduledTask.Settings.DisallowStartIfOnBatteries = $false
    $ScheduledTask.Settings.StopIfGoingOnBatteries = $false
    # Edit the trigger to have an expiration time 5 minutes after it runs
    $ScheduledTask.Triggers[0].EndBoundary = (Get-Date).AddMinutes(10).ToString("yyyy-MM-ddTHH:mm:ss")
    # Edit the task to delete itself after it expires
    $ScheduledTask.Settings.DeleteExpiredTaskAfter = "PT0S"
    # Commit the changes to the task
    $ScheduledTask | Set-ScheduledTask
} Else {
    # No connectivity to the domain so do nothing
}
#EndRegion