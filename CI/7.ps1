#Region: Detection
$KernelEvents = Get-WinEvent -ProviderName 'Microsoft-Windows-Kernel-Boot'
$KernelReboot = $KernelEvents | Where-Object {$_.Id -eq 27 -and $_.Message -eq "The boot type was 0x0."}
If ($KernelReboot[0].TimeCreated -ge (Get-Date).AddDays(-7)) {
    Return $true
}
#EndRegion
#Region: Installation
$KernelEvents = Get-WinEvent -ProviderName 'Microsoft-Windows-Kernel-Boot'
$KernelReboot = $KernelEvents | Where-Object {$_.Id -eq 27 -and $_.Message -eq "The boot type was 0x0."}
$KernelUpTime = New-TimeSpan -Start $KernelReboot[0].TimeCreated -End (Get-Date)
# Create registry settings for a custom URI so PowerShell can exectue scripts from a notification
New-Item "HKLM:\SOFTWARE\Classes\toastnotification" -Force
New-Item "HKLM:\SOFTWARE\Classes\toastnotification\DefaultIcon" -Force
New-Item "HKLM:\SOFTWARE\Classes\toastnotification\shell" -Force
New-Item "HKLM:\SOFTWARE\Classes\toastnotification\shell\open" -Force
New-Item "HKLM:\SOFTWARE\Classes\toastnotification\shell\open\command" -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Classes\toastnotification" -Name "(default)" -Value "URL:PowerShell Toast Notification Protocol" -PropertyType String -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Classes\toastnotification" -Name "URL Protocol" -Value "" -PropertyType String -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Classes\toastnotification\DefaultIcon" -Name "(default)" -Value "%windir%\System32\WindowsPowerShell\v1.0\powershell.exe,1" -PropertyType String -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Classes\toastnotification\shell" -Name "(default)" -Value "open" -PropertyType String -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Classes\toastnotification\shell\open\command" -Name "(default)" -Value "`"$env:ProgramData\ToastNotification\RestartComputer.cmd`" %1" -PropertyType String -Force
# Copy restart script to %ProgramData% so it can be called through the notification
New-Item -Path "$env:ProgramData\ToastNotification" -ItemType Directory -Force
Copy-Item -Path "$PSScriptHost\RestartComputer.cmd" -Destination "$env:ProgramData\ToastNotification\RestartComputer.cmd" -Force -Confirm:$false # RestartComputer.cmd is in the application content, and triggers the PowerShell script
Copy-Item -Path "$PSScriptHost\RestartComputer.ps1" -Destination "$env:ProgramData\ToastNotification\RestartComputer.ps1" -Force -Confirm:$false # RestartComputer.ps1 is in the application content, and runs Restart-Computer
# Show a toast notification prompting the user to restart, with an option to snooze, or restart
$ToastXml = @"
<toast>
    <visual>
        <binding template="ToastGeneric">
            <text>Restart Notification</text>
            <text>Your computer has not been restarted for $($KernelUpTime.Days) days. Please complete a restart as soon as possible.</text>
            <image placement="appLogoOverride" src="$PSScriptHost\Restart.png"/>
        </binding>
    </visual>
    <actions>
        <action content="Snooze" activationType="protocol" arguments="" />
        <action content="Restart" activationType="protocol" arguments="toastnotification://trigger" />
    </actions>
</toast>
"@
$XmlDocument = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]::New()
$XmlDocument.LoadXml($ToastXml)
$AppId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]::CreateToastNotifier($AppId).Show($XmlDocument)
#EndRegion