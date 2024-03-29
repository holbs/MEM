$SoftwareToRemove = @(
    "Mozilla Firefox *"
)
$RegistryLocations = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)
$RegistryLocations | Foreach-Object {
    $RegistryKeys = Get-ItemProperty "$_\*"
    Foreach ($Key in $RegistryKeys) {
        If ($Key.DisplayName -like $SoftwareToRemove) {
            Start-Process -WindowStyle hidden -FilePath $Key.UninstallString -ArgumentList "/s" -Wait
        }
    }
}