#Region: Detection
If (Test-Path -Path "$env:SystemDrive\Users\*\AppData\*\Microsoft\Teams") {Write-Output "Installed"}
If (Test-Path -Path "$env:SystemDrive\Users\*\AppData\*\Microsoft\Windows\Start Menu\Programs\Teams.lnk") {Write-Output "Installed"}
If (Test-Path -Path "$env:SystemDrive\Users\*\AppData\*\Microsoft\Windows\Start Menu\Programs\Teams Classic.lnk") {Write-Output "Installed"}
# Check for Teams Machine-Wide Installer in the registry
Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall' | Get-ItemProperty | Where-Object {$_.DisplayName -eq 'Teams Machine-Wide Installer'} | Foreach-Object {Write-Output "Installed"}
#EndRegion
#Region: Uninstall
Get-Item -Path "$env:SystemDrive\Users\*\AppData\*\Microsoft\Teams\update.exe" | Foreach-Object {
    $Teams = Start-Process -FilePath $_.FullName -ArgumentList "-uninstall -s" -PassThru
    Wait-Process -Id $Teams.Id
}
# Search through the registry for installs of Teams Machine-Wide Installer and uninstall
Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall' | Get-ItemProperty | Where-Object {$_.DisplayName -eq 'Teams Machine-Wide Installer'} | Foreach-Object {
    $DisplayName = $_.GetValue('DisplayName').Replace(" ","_")
    $ProductCode = $_.PSChildName
    $Version     = $_.GetValue('DisplayVersion')
    # Splatting to pass the product code to msiexec to uninstall the software
    $Uninstall = @{
        FilePath = "$env:WINDIR\System32\msiexec.exe"
        ArgumentList = @(
            "/x",
            "$ProductCode",
            "/qn",
            "/L*vx! $env:WINDIR\Logs\Software\$($DisplayName)_$($Version)_Uninstall.log"
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
# Clean up folders and shortcuts
Get-ChildItem -Path "$env:SystemDrive\Users\*\AppData\*\Microsoft\Teams" -Recurse -File | Remove-Item -Force -Confirm:$false
Get-ChildItem -Path "$env:SystemDrive\Users\*\AppData\*\Microsoft\Teams" -Recurse -Directory | Remove-Item -Force -Confirm:$false
Get-Item -Path "$env:SystemDrive\Users\*\AppData\*\Microsoft\Teams" | Remove-Item -Force -Confirm:$false
Get-Item -Path "$env:SystemDrive\Users\*\AppData\*\Microsoft\Windows\Start Menu\Programs\Teams.lnk" | Remove-Item -Force -Confirm:$false
Get-Item -Path "$env:SystemDrive\Users\*\AppData\*\Microsoft\Windows\Start Menu\Programs\Teams Classic.lnk" | Remove-Item -Force -Confirm:$false
#EndRegion