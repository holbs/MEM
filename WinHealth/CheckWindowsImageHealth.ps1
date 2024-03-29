#Region: Detection
If ((Repair-WindowsImage -Online -CheckHealth).ImageHealthState -eq "Healthy") {
    Return $true
} Else {
    Return $false
}
#EndRegion
#Region: Remediation
$CheckHealth = Repair-WindowsImage -Online -CheckHealth
$ScanHealth = Repair-WindowsImage -Online -ScanHealth
$RestoreHealth = Repair-WindowsImage -Online -RestoreHealth
If ($CheckHealth.RestartNeeded -eq $true -or $ScanHealth.RestartNeeded -eq $true -or $RestoreHealth.RestartNeeded -eq $true) {
    # Prompt the user to restart the workstation by displaying a toast notification
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $Notification = New-Object System.Windows.Forms.NotifyIcon
    $Notification.Icon = [System.Drawing.SystemIcons]::Warning
    $Notification.BalloonTipTitle = "Restart Notification"
    $Notification.BalloonTipText = "A system scan has found Windows image corruption. Please restart your workstation to complete repairs."
    $Notification.Visible = $true
    $Notification.ShowBalloonTip(300000)
} Else {
    # Trigger SFC /scannow
    Start-Process -WindowStyle hidden -FilePath "$env:WINDIR\System32\sfc.exe" -ArgumentList "/scannow"
    Wait-Process -Name "SFC" -ErrorAction SilentlyContinue
    # Prompt the user to restart the workstation by displaying a toast notification
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $Notification = New-Object System.Windows.Forms.NotifyIcon
    $Notification.Icon = [System.Drawing.SystemIcons]::Warning
    $Notification.BalloonTipTitle = "Restart Notification"
    $Notification.BalloonTipText = "A system scan has found Windows image corruption. Please restart your workstation to complete repairs."
    $Notification.Visible = $true
    $Notification.ShowBalloonTip(300000)
}
#EndRegion