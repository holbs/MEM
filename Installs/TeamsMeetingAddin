<#
    This script installs the Microsoft Teams Addin for Microsoft Office, which is required for the Teams Meeting Outlook Addin to appear in Microsoft Outlook.
    The Application is dependant on another package to install MSTeams, so we can assume that MSTeams in installed, and therefore the installer for the addin is present.
    For the most part, the MSTeams installation manages the installation of the addin but this can fail, and the addin can be left in a broken state. Therefore this should be deployed as available, but dependant on the MSTeams required.
    Before it attempts to install, it checks if it's already installed, and if the install source matches the MSTeams folder path.
#>

#Requires -RunAsAdministrator

#Region: Detection
$MSTeams = Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'MSTeams'}
$TeamsMeetingAddin = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall' | Get-ItemProperty | Where-Object {$_.DisplayName -eq 'Microsoft Teams Meeting Add-in for Microsoft Office'}
# If the Teams Meeting Addin InstallSource matches the MSTeams InstallLocation, we can assume it's installed, if the Teams Meeting Addin is not present, or doesn't match then it's not installed (properly)
If ($TeamsMeetingAddin -and $TeamsMeetingAddin.InstallSource -eq ([string]$MSteams.InstallLocation -Replace('AppxManifest.xml',''))) {
    Write-Output "Microsoft Teams Meeting Add-in for Microsoft Office is installed"
}
#EndRegion
#Region: Installation
$TeamsMeetingAddin = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall' | Get-ItemProperty | Where-Object {$_.DisplayName -eq 'Microsoft Teams Meeting Add-in for Microsoft Office'}
# If the Teams Meeting Addin is in the registry but we're running the installation script then it must've failed detection and be a broken install that we need to repair and then uninstall
If ($TeamsMeetingAddin) {
    # We will start by collecting the MSTeams version number from the Teams Meeting Addin InstallSource out of the registry
    $InstallSource = $TeamsMeetingAddin.InstallSource
    $InstallSourceVersion = $InstallSource -Match "_(\d+\.\d+\.\d+\.\d+)_" | Out-Null; $Matches[1]
    # Now download the MSIX for that version of MSTeams from Microsoft
    $Url = "https://statics.teams.cdn.office.net/production-windows-x64/$InstallSourceVersion/MSTeams-x64.msix"
    & $env:WINDIR\System32\curl.exe -s -o "$env:TEMP\MSTeams-x64.msix" -l $Url
    # Now that we have downloaded the msix, we need to convert this to a zip file, and extract it so we can collect the original MSI for the Teams Meeting Addin
    Rename-Item -Path "$env:TEMP\MSTeams-x64.msix" -NewName "$env:TEMP\MSTeams-x64.zip"
    Expand-Archive -Path "$env:TEMP\MSTeams-x64.zip" -DestinationPath "$env:TEMP\MSTeams-x64-$InstallSourceVersion"
    $MicrosoftTeamsMeetingAddinInstaller = "$env:TEMP\MSTeams-x64-$InstallSourceVersion\MicrosoftTeamsMeetingAddinInstaller.msi"
    # Now we can use the Teams Meeting Addin MSI to repair the installation, then uninstall it
    New-Item -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\Software" -ItemType Directory -Force
    $Install = Start-Process -FilePath "$env:WINDIR\System32\msiexec.exe" -ArgumentList "/i $MicrosoftTeamsMeetingAddinInstaller /qn REINSTALL=ALL REINSTALLMODE=vomus /L*v $env:ProgramData\Microsoft\IntuneManagementExtension\Logs\Software\MicrosoftTeamsMeetingAddin_$($TeamsMeetingAddin.DisplayVersion)_Install.log" -PassThru
    Wait-Process -Id $Install.Id
    $Repair = Start-Process -FilePath "$env:WINDIR\System32\msiexec.exe" -ArgumentList "/fa $MicrosoftTeamsMeetingAddinInstaller /qn /L*v $env:ProgramData\Microsoft\IntuneManagementExtension\Logs\Software\MicrosoftTeamsMeetingAddin_$($TeamsMeetingAddin.DisplayVersion)_Repair.log" -PassThru
    Wait-Process -Id $Repair.Id
    $Uninstall = Start-Process -FilePath "$env:WINDIR\System32\msiexec.exe" -ArgumentList "/x $($TeamsMeetingAddin.PsChildName) /qn /L*v $env:ProgramData\Microsoft\IntuneManagementExtension\Logs\Software\MicrosoftTeamsMeetingAddin_$($TeamsMeetingAddin.DisplayVersion)_Uninstall.log" -PassThru
    Wait-Process -Id $Uninstall.Id
}
# If the Teams Meeting Addin wasn't in the registry, or we have now uninstalled it with the steps above, we can install it from the existing MSTeams directory from the dependant application
$MSTeams = Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'MSTeams'}
$TeamsMeetingAddinMSTeamsInstallerPath = $MSTeams.InstallLocation -Replace('AppxManifest.xml','') + "MicrosoftTeamsMeetingAddinInstaller.msi"
$TeamsMeetingAddinInstall = Start-Process -FilePath "$env:WINDIR\System32\msiexec.exe" -ArgumentList "/i $TeamsMeetingAddinMSTeamsInstallerPath /qn /L*v $env:ProgramData\Microsoft\IntuneManagementExtension\Logs\Software\MicrosoftTeamsMeetingAddin_$($MSTeams.DisplayVersion)_Install.log" -PassThru
Wait-Process -Id $TeamsMeetingAddinInstall.Id
#EndRegion