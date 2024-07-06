#Region: Detection
If ((Repair-WindowsImage -Online -CheckHealth).ImageHealthState -eq "Healthy") {
    Return $true
}
#EndRegion
#Region: Remediation
$CheckHealth = Repair-WindowsImage -Online -CheckHealth
$ScanHealth = Repair-WindowsImage -Online -ScanHealth
$RestoreHealth = Repair-WindowsImage -Online -RestoreHealth
# If the Repair-WindowsImage commands did not require a restart then run sfc /scannow, too
If ($CheckHealth.RestartNeeded -ne $true -and $ScanHealth.RestartNeeded -ne $true -and $RestoreHealth.RestartNeeded -ne $true) {
    Start-Process -WindowStyle hidden -FilePath "$env:WINDIR\System32\sfc.exe" -ArgumentList "/scannow"
    Wait-Process -Name "sfc" -ErrorAction SilentlyContinue
}
#EndRegion
