# Display name of software to search for and remove
$SoftwareToRemove = @(
    "Teams Machine-Wide Installer"
)
# Registry paths to search through
$RegistryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)
# Loop through the registry looking for $SoftwareToRemove and uninstall if found
Foreach ($Path in $RegistryPaths) {
    $RegistryKeys = Get-ChildItem -Path $Path | Where-Object {$_.PSChildName -match '^{[A-Z0-9]{8}-([A-Z0-9]{4}-){3}[A-Z0-9]{12}}$'}
    Foreach ($Key in $RegistryKeys) {
        $DisplayName = $Key.GetValue('DisplayName')
        $ProductCode = $Key.PSChildName
        $Version     = $Key.GetValue('DisplayVersion')
        If ($DisplayName -in $SoftwareToRemove) {
            # Splatting to pass the product code to msiexec to uninstall the software
            $Uninstall = @{
                FilePath = "$env:WINDIR\System32\msiexec.exe"
                ArgumentList = @(
                    "/x",
                    "$ProductCode",
                    "/qn",
                    "/L*vx! $env:WINDIR\Logs\Software\$($DisplayName.Replace(" ","_"))_$($Version)_Uninstall.log"
                )
                PassThru = $true
            }
            $Process = Start-Process @Uninstall
            Wait-Process -Id $Process.Id
            # Wait a bit longer
            Start-Sleep -Seconds 5
            # If the uninstall returns anything other than exit code 0, exit the script with that exit code to pass it back to ConfigMgr (or Intune, or anything else) to handle based on defined exit codes
            If ($Process.ExitCode -ne 0) {
                [Environment]::Exit($Process.ExitCode)
            }
        }
    }
}