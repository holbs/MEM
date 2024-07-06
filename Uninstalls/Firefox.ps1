#Region: Detection
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall","HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | Foreach-Object {
    $RegistryKeys = Get-ItemProperty "$_\*"
    Foreach ($Key in $RegistryKeys) {
        If ($Key.DisplayName -like "Mozilla Firefox *") {
            Return "Installed"
        }
    }
}
#EndRegion
#Region: Uninstall
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall","HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | Foreach-Object {
    $RegistryKeys = Get-ItemProperty "$_\*"
    Foreach ($Key in $RegistryKeys) {
        If ($Key.DisplayName -like "Mozilla Firefox *") {
            Start-Process -WindowStyle hidden -FilePath $Key.UninstallString -ArgumentList "/s" -Wait
        }
    }
}
#EndRegion
