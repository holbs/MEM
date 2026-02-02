<#
.SYNOPSIS
    Uninstalls Zoom.
.DESCRIPTION
    The detection script is used to detect if Zoom is installed by checking both system-wide and per-user installation locations. The uninstall program uses Zoom's CleanZoom.exe utility to silently remove Zoom from the system.
.NOTES
    Set up an application using the detection script to detect Zoom installations. Set the uninstall script as the uninstall program. Deploy the uninstall program to remove Zoom silently. The uninstall program will also move the cleanzoom.log file to a set folder for troubleshooting.
.LINK
    CleanZoom.exe can be downloaded from: https://assets.zoom.us/docs/msi-templates/CleanZoom.zip
#>

#Region: Detection
$Installs = @()
$Installs += Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall","HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | Get-ItemProperty | Where-Object {$_.DisplayName -like "Zoom Workplace (*)"}
$Installs += Get-Item -Path "$env:SystemDrive\Users\*\AppData\Roaming\Zoom\bin\Zoom.exe" -ErrorAction SilentlyContinue
If ($Installs.Count -gt 0) {
    Write-Output "Installed"
    Exit 0
} Else {
    Write-Output "Not Installed"
    Exit 1
}
#EndRegion
#Region: Uninstall
Try {
    $Zoom = Start-Process -FilePath "$PSScriptRoot\CleanZoom.exe" -ArgumentList "/silent" -PassThru
    Wait-Process -Id $Zoom.Id -Timeout 300 -ErrorAction Stop
    # Create logs folder if it doesn't exist
    If (-not (Test-Path -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\Software")) {
        New-Item -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\Software" -ItemType Directory -Force
    }
    # Move the cleanzoom.log file from the script root to a set folder
    Move-Item -Path "$PSScriptRoot\cleanzoom.log" -Destination "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\Software" -Force
    # Exit with the same code as CleanZoom.exe
    Exit $Zoom.ExitCode
} Catch {
    Write-Output "Failed to run CleanZoom.exe: $_"
    # Exit with the same code as CleanZoom.exe
    Exit $Zoom.ExitCode
}
#EndRegion