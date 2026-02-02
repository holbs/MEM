<#
.SYNOPSIS
    Uninstalls Zoom installed as a user.
.DESCRIPTION
    The detection script is used to detect if Zoom is installed by checking the per-user installation locations. The uninstall program uses Zoom's CleanZoom.exe utility to silently remove Zoom from the system.
.NOTES
    Set up an application using the detection script to detect Zoom installations. Set the uninstall script as the uninstall program. Deploy the uninstall program to remove Zoom silently. The uninstall program will also move the cleanzoom.log file to a set folder for troubleshooting.
.LINK
    CleanZoom.exe can be downloaded from: https://assets.zoom.us/docs/msi-templates/CleanZoom.zip
#>

#Region: Detection
$Zoom += Get-Item -Path "$env:SystemDrive\Users\*\AppData\Roaming\Zoom\bin\Zoom.exe" -ErrorAction SilentlyContinue
If ($Zoom) {
    Exit 0
} Else {
    Exit 1
}
#EndRegion
#Region: Uninstall
Try {
    $Zoom = Start-Process -FilePath "$PSScriptRoot\CleanZoom.exe" -ArgumentList "/silent" -PassThru
    Get-Process -Id $Zoom.Id -ErrorAction SilentlyContinue | Wait-Process -Timeout 300 -ErrorAction Stop
    # Create logs folder if it doesn't exist
    If (-not (Test-Path -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\Software" -PathType Container)) {
        New-Item -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\Software" -ItemType Directory -Force
    }
    # Move the cleanzoom.log file from the script root to a set folder
    Move-Item -Path "$PSScriptRoot\cleanzoom.log" -Destination "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\Software" -Force -ErrorAction SilentlyContinue
    # Exit with the same code as CleanZoom.exe
    Exit $Zoom.ExitCode
} Catch {
    Write-Output "Failed to run CleanZoom.exe: $_"
    # Exit with the same code as CleanZoom.exe if it was started
    If ($Zoom) {
        Exit $Zoom.ExitCode
    } Else {
        Exit 1
    }
}
#EndRegion