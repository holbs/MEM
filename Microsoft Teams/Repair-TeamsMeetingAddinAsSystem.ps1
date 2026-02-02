<#
.SYNOPSIS
    Repair the Microsoft Teams Meeting Add-in for Microsoft Office installation as SYSTEM.
.DESCRIPTION
    This script repairs the Microsoft Teams Meeting Add-in for Microsoft Office installation by downloading the appropriate version of the MSTeams MSIX package from Microsoft, extracting the MSI installer for the Teams Meeting Add-in, and then running a repair installation using msiexec.
.NOTES
    This script is intended to be run in the user context to repair the Teams Meeting Add-in for Microsoft Office which installs per-user.
#>

# Get the installed Teams Meeting Add-in for Microsoft Office version from the registry then extract the version number from the InstallSource
$TeamsMeetingAddin = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall' | Get-ItemProperty | Where-Object {$_.DisplayName -eq 'Microsoft Teams Meeting Add-in for Microsoft Office'}
$TeamsMeetingAddinInstallSource = $TeamsMeetingAddin.InstallSource
$TeamsMeetingAddinVersion = $TeamsMeetingAddinInstallSource -Match "_(\d+\.\d+\.\d+\.\d+)_" | Out-Null; $Matches[1]

# Using the version number, build a URI to download the corresponding MSTeams MSIX package from Microsoft to the TEMP directory
$Url = "https://statics.teams.cdn.office.net/production-windows-x64/$TeamsMeetingAddinVersion/MSTeams-x64.msix"
Invoke-WebRequest -Uri $Url -OutFile "$env:TEMP\MSTeams-x64.msix" -UseBasicParsing

# Convert the downloaded MSIX to a ZIP and extract it to access the Teams Meeting Add-in MSI installer
Rename-Item -Path "$env:TEMP\MSTeams-x64.msix" -NewName "$env:TEMP\MSTeams-x64.zip"
Expand-Archive -Path "$env:TEMP\MSTeams-x64.zip" -DestinationPath "$env:TEMP\MSTeams-x64"

# Build out a hashtable to pass to msiexec to perform a repair installation of the Teams Meeting Add-in
$Install = @{
    FilePath = "$env:WINDIR\System32\msiexec.exe"
    ArgumentList = @(
        "/i",
        "$env:TEMP\MSTeams-x64\MicrosoftTeamsMeetingAddinInstaller.msi",
        "/qn",
        "REINSTALL=ALL",
        "REINSTALLMODE=vomus",
        "/L*vx! $env:TEMP\MicrosoftTeamsMeetingAddinInstallerRepair.log"
    )
    PassThru = $true
}

# Start the repair installation process and wait for it to complete
$TeamsMeetingAddinRepair = Start-Process @Install
Get-Process -Id $TeamsMeetingAddinRepair.Id | Wait-Process -Timeout 300
Start-Sleep -Seconds 5

# Remove the downloaded and extracted files from TEMP
Remove-Item -Path "$env:TEMP\MSTeams-x64.zip" -Force -Confirm:$false
Remove-Item -Path "$env:TEMP\MSTeams-x64" -Recurse -Force -Confirm:$false