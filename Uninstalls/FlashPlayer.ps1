#Region: Detection
If (Test-Path -Path "$env:WINDIR\System32\Macromed\Flash") {Return "Installed"}
If (Test-Path -Path "$env:WINDIR\SysWOW64\Macromed\Flash") {Return "Installed"}
If (Test-Path -Path "$env:SYSTEMDRIVE\Users\*\AppData\Roaming\Adobe\Flash Player") {Return "Installed"}
If (Test-Path -Path "$env:SYSTEMDRIVE\Users\*\AppData\Roaming\Macromedia\Flash Player") {Return "Installed"}
If (Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Adobe Flash*') {Return "Installed"}
If (Test-Path -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Adobe Flash*') {Return "Installed"}
#EndRegion
#Region: Uninstall
Start-Process -WindowStyle hidden -FilePath "$PSScriptRoot\uninstall_flash_player.exe" -ArgumentList "-uninstall"
Wait-Process -Name "uninstall_flash_player"
Start-Sleep -Seconds '5'
# Unregister the DLLs
$Dll = @("$env:WINDIR\System32\Macromed\Flash\*.dll","$env:WINDIR\SysWOW64\Macromed\Flash\*.dll")
Foreach ($File in $Dll) {
    $FilePath = Get-Item -Path $File | Select-Object -ExpandProperty FullName
    If ($FilePath) {
        Start-Process -WindowStyle hidden -Path "$env:WINDIR\System32\regsvr32.exe" -ArgumentList "/u /s $Filepath" -Wait
    }
}
# Take ownership of the folders and the content
Start-Process -WindowStyle hidden -FilePath "$env:WINDIR\System32\takeown.exe" -ArgumentList "/F $env:WINDIR\System32\Macromed\Flash\* /R /A" -Wait
Start-Process -WindowStyle hidden -FilePath "$env:WINDIR\System32\icalcs.exe" -ArgumentList "$env:WINDR\System32\Macromed\Flash\*.* /T /grant administrators:F" -Wait
Start-Process -WindowStyle hidden -FilePath "$env:WINDIR\System32\takeown.exe" -ArgumentList "/F $env:WINDIR\SysWOW64\Macromed\Flash\* /R /A" -Wait
Start-Process -WindowStyle hidden -FilePath "$env:WINDIR\System32\icalcs.exe" -ArgumentList "$env:WINDR\SysWOW64\Macromed\Flash\*.* /T /grant administrators:F" -Wait
# Remove the deny write attribute Access Controls from the .ocx files
$Ocx = @("$env:WINDIR\System32\Macromed\Flash\*.ocx","$env:WINDIR\SysWOW64\Macromed\Flash\*.ocx")
Foreach ($File in $Ocx) {
    $FilePath = Get-Item -Path $File | Select-Object -ExpandProperty FullName
    If ($FilePath) {
        Foreach ($Item in $FilePath) {
            $ACL = Get-Acl -Path $Item
            $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone","WriteAttributes","Deny")
            $ACL.RemoveAccessRule($AccessRule)
            $ACL | Set-Acl -Path $Item
        }
    }
}
# Remove the folders
Remove-Item -Path "$env:WINDIR\System32\Macromed\Flash" -Recurse -Force -Confirm:$false
Remove-Item -Path "$env:WINDIR\SysWOW64\Macromed\Flash" -Recurse -Force -Confirm:$false
Remove-Item -Path "$env:SYSTEMDRIVE\Users\*\AppData\Roaming\Adobe\Flash Player" -Recurse -Force -Confirm:$false
Remove-Item -Path "$env:SYSTEMDRIVE\Users\*\AppData\Roaming\Macromedia\Flash Player" -Recurse -Force -Confirm:$false
# Remove the entries from appwiz.cpl
Get-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Adobe Flash*' | Remove-Item -Recurse -Force -Confirm:$false
Get-Item -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Adobe Flash*' | Remove-Item -Recurse -Force -Confirm:$false
#EndRegion
