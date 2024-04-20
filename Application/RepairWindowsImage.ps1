#Region: Detection
If ((Repair-WindowsImage -Online -CheckHealth).ImageHealthState -eq "Healthy") {
    Return $true
}
#EndRegion
#Region: Installation
$CheckHealth = Repair-WindowsImage -Online -CheckHealth
$ScanHealth = Repair-WindowsImage -Online -ScanHealth
$RestoreHealth = Repair-WindowsImage -Online -RestoreHealth
# If the Repair-WindowsImage commands did not require a restart then run sfc /scannow before prompting for reboot
If ($CheckHealth.RestartNeeded -ne $true -and $ScanHealth.RestartNeeded -ne $true -and $RestoreHealth.RestartNeeded -ne $true) {
    Start-Process -WindowStyle hidden -FilePath "$env:WINDIR\System32\sfc.exe" -ArgumentList "/scannow"
    Wait-Process -Name "sfc" -ErrorAction SilentlyContinue
}
# Create registry settings for a custom URI so PowerShell can exectue scripts from a notification
New-Item "HKLM:\SOFTWARE\Classes\toastshell" -Force
New-Item "HKLM:\SOFTWARE\Classes\toastshell\DefaultIcon" -Force
New-Item "HKLM:\SOFTWARE\Classes\toastshell\shell" -Force
New-Item "HKLM:\SOFTWARE\Classes\toastshell\shell\open" -Force
New-Item "HKLM:\SOFTWARE\Classes\toastshell\shell\open\command" -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Classes\toastshell" -Name "(default)" -Value "URL:PowerShell Toast Notification Protocol" -Type String -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Classes\toastshell" -Name "URL Protocol" -Value "" -Type String -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Classes\toastshell\DefaultIcon" -Name "(default)" -Value "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe,1" -Type String -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Classes\toastshell\shell" -Name "(default)" -Value "open" -Type String -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Classes\toastshell\shell\open\command" -Name "(default)" -Value "`"$env:WINDIR\ToastShell\ToastShell.cmd`" %1" -Type String -Force
# Copy scripts to %ProgramData% so they can be called through the notification
New-Item -Path "$env:WINDIR\ToastShell" -ItemType Directory -Force
Copy-Item -Path "$PSScriptHost\ToastShell.cmd" -Destination "$env:WINDIR\ToastShell\ToastShell.cmd" -Force -Confirm:$false # %windir%\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle hidden -ExecutionPolicy bypass -NoLogo -NoProfile -File "%~dp0ToastShell.ps1" "%*"
Copy-Item -Path "$PSScriptHost\ToastShell.ps1" -Destination "$env:WINDIR\ToastShell\ToastShell.ps1" -Force -Confirm:$false # Start-Process -FilePath "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList $Args.Trim('/').Replace('toastshell://',"")
# Show a toast notification prompting the user to restart, with an option to snooze, or restart (snooze just dismisses until ConfigMgr completes detection again and tries to 'install')
$ToastXml = @"
<toast>
    <visual>
        <binding template="ToastGeneric">
            <text>Restart Notification</text>
            <text>A system scan has found Windows image corruption. Please restart your computer to complete repairs.</text>
            <image placement="appLogoOverride" src="$PSScriptHost\Restart.png"/>
        </binding>
    </visual>
    <actions>
        <action content="Snooze" activationType="protocol" arguments="" />
        <action content="Restart" activationType="protocol" arguments="toastshell://Restart-Computer" />
    </actions>
</toast>
"@
$XmlDocument = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]::New()
$XmlDocument.LoadXml($ToastXml)
$AppId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]::CreateToastNotifier($AppId).Show($XmlDocument)
#EndRegion
