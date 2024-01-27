#Region: Detection
$File = Test-Path "$env:ProgramData\Qualys\log4j_summary.out"
$Task = Get-ScheduledTask -TaskName "Log4ShellScanner"
If ($File -and $Task) {
    $ScanResults = Get-Content -Path "$env:ProgramData\Qualys\log4j_summary.out" | Select-String "vulnerabilitiesFound:" | Out-String
    $Vulnerabilities = $ScanResults.Split(':')[-1].Trim()
    If ([Int32]$Vulnerabilities -eq 0) {
        Return "Remediated"
    }
}
#EndRegion
#Region: Installation
$Task = Get-ScheduledTask -TaskName "Log4ShellScanner"
If ($Task) {
    If (Test-Path "$env:ProgramData\Qualys\Scanner") {
        Get-Item -Path "$PSScriptRoot\*.exe" | Copy-Item -Destination "$env:ProgramData\Qualys\Scanner"
    } Else {
        New-Item -Path "$env:ProgramData\Qualys\Scanner" -ItemType Directory
        Get-Item -Path "$PSScriptRoot\*.exe" | Copy-Item -Destination "$env:ProgramData\Qualys\Scanner"
    }
    # Create scheduled task to run Log4jScanner.exe once a week for script detection to check
    $TaskActions = New-ScheduledTaskAction -Execute '%ProgramData%\Qualys\Scanner\Log4JScanner.exe' -Argument '/scan /report_sig'
    $TaskTimeSpan = New-TimeSpan -Hours 3
    $TaskTrigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek Tuesday -At 11am -RandomDelay $TaskTimeSpan
    $TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries
    Register-ScheduledTask -TaskName "Log4ShellScanner" Description "Runs Log4JScanner.exe to check for Log4J vulnerabilities on the system" -Action $TaskActions -Trigger $TaskTrigger -Settings $TaskSettings
}
$Scan = Start-Process -WindowStyle hidden -FilePath "$PSScriptRoot\Log4JScanner.exe" -ArgumentList "/scan /report_sig" -PassThru
Wait-Process -Id $Scan.Id
$ScanResults = Get-Content -Path "$env:ProgramData\Qualys\log4j_summary.out" | Select-String "vulnerabilitiesFound:" | Out-String
$Vulnerabilities = $ScanResults.Split(':')[-1].Trim()
If ([Int32]$Vulnerabilities -gt 0) {
    $Remediate = Start-Process -WindowStyle hidden -FilePath "$PSScriptRoot\Log4JRemediate.exe" -ArgumentList "/remediate_sig" -PassThru
    Wait-Process -Id $Remediate.Id
    $Rescan = Start-Process -WindowStyle hidden -FilePath "$PSScriptRoot\Log4JScanner.exe" -ArgumentList "/scan /report_sig" -PassThru
    Wait-Process -Id $Rescan.Id
}
#EndRegion
