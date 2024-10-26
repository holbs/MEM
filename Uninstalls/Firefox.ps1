#Region: Detection
$PathsToCheck = @(
    "${env:SystemDrive}\Users\*\AppData\*\*Firefox*",
    "${env:ProgramFiles}\*Firefox*",
    "${env:ProgramFiles(x86)}\*Firefox*",
    "${env:SystemDrive}\Users\*\AppData\*\Microsoft\Windows\Start Menu\Programs\*Firefox*.lnk",
    "${env:ProgramData}\Microsoft\Windows\Start Menu\Programs\*Firefox*.lnk"
)
$PathsToCheck | Foreach-Object {
    If (Test-Path -Path $_) {
        Write-Output "Installed"
    }
}
#EndRegion
#Region: Uninstall
$helperPaths = @(
    "${env:SystemDrive}\Users\*\AppData\*\*Firefox*\uninstall\helper.exe",
    "${env:ProgramFiles}\*Firefox*\uninstall\helper.exe",
    "${env:ProgramFiles(x86)}\*Firefox*\uninstall\helper.exe"
)
# Find any installation of Firefox and uninstall using helper.exe
$helperPaths | Foreach-Object {
    If (Test-Path -Path $_) {
        Get-Item -Path $_ | Select-Object -ExpandProperty FullName | Foreach-Object {
            $Firefox = Start-Process -FilePath $_.FullName -ArgumentList "/s" -PassThru
            Wait-Process -Id $Firefox.Id
        }
    }
}
# Search through the registry for installs and uninstall if present there
Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall' | Get-ItemProperty | Where-Object {$_.DisplayName -like 'Mozilla Firefox *'} | Foreach-Object {
    $Firefox = Start-Process -WindowStyle hidden -FilePath $_.UninstallString -ArgumentList "/s" -PassThru
    Wait-Process -Id $Firefox.Id
}
# Clean up folders and shortcuts
Get-Item -Path "${env:SystemDrive}\Users\*\AppData\*\*Firefox*" | Remove-Item -Recurse -Force
Get-Item -Path "${env:ProgramFiles}\*Firefox*" | Remove-Item -Recurse -Force
Get-Item -Path "${env:ProgramFiles(x86)}\*Firefox*" | Remove-Item -Recurse -Force
Get-Item -Path "${env:SystemDrive}\Users\*\AppData\*\Microsoft\Windows\Start Menu\Programs\*Firefox*.lnk" | Remove-Item -Force
Get-Item -Path "${env:ProgramData}\Microsoft\Windows\Start Menu\Programs\*Firefox*.lnk" | Remove-Item -Force
#EndRegion