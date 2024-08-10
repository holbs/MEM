#Region: Detection
$InstalledSoftware = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall","HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | Get-ItemProperty
If ($InstalledSoftware.DisplayName -match "Zoom") {
    Write-Output "Installed"
}
If (Test-Path -Path "$env:SystemDrive\Users\*\AppData\*\Zoom") {
    Write-Output "Installed"
}
#EndRegion
#Region: Uninstall
Start-Process -WindowStyle hidden -FilePath "$PSScriptRoot\CleanZoom.exe" -ArgumentList "/silent" -Wait <# Download from: https://assets.zoom.us/docs/msi-templates/CleanZoom.zip #>
#EndRegion