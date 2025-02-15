<#
.DESCRIPTION
    Scripts for detecting and repairing the Microsoft Teams Meeting Add-in for Microsoft Office in system context. To repair we download the MSTeams installer that matches the InstallSource from the registry, and repair with that
#>

#Region: Detection
$TeamsMeetingAddin = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall' | Get-ItemProperty | Where-Object {$_.DisplayName -eq 'Microsoft Teams Meeting Add-in for Microsoft Office'}
If ($TeamsMeetingAddin) {
    $TeamsMeetingAddinVersion = $TeamsMeetingAddin.DisplayVersion
    If (Test-Path -Path "$env:ProgramFiles\Microsoft\TeamsMeetingAdd-in\$TeamsMeetingAddinVersion") {
        If (Test-Path -Path "$env:ProgramFiles\Microsoft\TeamsMeetingAdd-in\$TeamsMeetingAddinVersion\AddinInstaller.dll") {
            Write-Output "Installed"
        } Else {
            # Not installed
        }
    } Else {
        # Not installed  
    }
}
#EndRegion
#Region: Repair
$TeamsMeetingAddin = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall' | Get-ItemProperty | Where-Object {$_.DisplayName -eq 'Microsoft Teams Meeting Add-in for Microsoft Office'}
$TeamsMeetingAddinInstallSource = $TeamsMeetingAddin.InstallSource
# Get the MSTeams version number from the InstallSource string
$TeamsMeetingAddinVersion = $TeamsMeetingAddinInstallSource -Match "_(\d+\.\d+\.\d+\.\d+)_" | Out-Null; $Matches[1]
# Now download the MSIX for that version of MSTeams from Microsoft
$Url = "https://statics.teams.cdn.office.net/production-windows-x64/$Version/MSTeams-x64.msix"
& $env:WINDIR\System32\curl.exe -s -o "$env:TEMP\MSTeams-x64.msix" -l $Url
# Check that the download was successful
If (Test-Path -Path "$env:TEMP\MSTeams-x64.msix") {
    # Now that we have downloaded the msix, we need to convert this to a zip file, and extract it so we can collect the original MSI for the Teams Meeting Add-in
    Rename-Item -Path "$env:TEMP\MSTeams-x64.msix" -NewName "$env:TEMP\MSTeams-x64.zip"
    Expand-Archive -Path "$env:TEMP\MSTeams-x64.zip" -DestinationPath "$env:TEMP\MSTeams-x64"
    $MSTeamsMeetingAddinInstaller = "$env:TEMP\MSTeams-x64\MicrosoftTeamsMeetingAddinInstaller.msi"
    # Make a copy of the MSI so we can extract the version number
    Copy-Item -Path $MSTeamsMeetingAddinInstaller -Destination "$env:TEMP\MicrosoftTeamsMeetingAddinInstaller.msi" -Force
    $MSTeamsMeetingAddinInstallerInTemp = "$env:TEMP\MicrosoftTeamsMeetingAddinInstaller.msi"
    # Load the copied MSI so we can extract the version number
    $Installer = New-Object -ComObject WindowsInstaller.Installer
    $Database = $Installer.OpenDatabase($MSTeamsMeetingAddinInstallerInTemp, 0)
    $View = $Database.OpenView("SELECT * FROM Property WHERE Property = 'ProductVersion'")
    $View.Execute()
    $Record = $View.Fetch()
    $Version = $Record.StringData(1)
    # Create the folder for the version of the Teams Meeting Add-in installer if it doesn't exist
    New-Item -Path "$env:ProgramFiles\Microsoft\TeamsMeetingAdd-in\$Version" -ItemType Directory -Force
    # Splatting to pass the original downloaded MSI installer to msiexec to repair the install
    $Install = @{
        FilePath = "$env:WINDIR\System32\msiexec.exe"
        ArgumentList = @(
            "/i",
            "$MSTeamsMeetingAddinInstaller",
            "/qn",
            "ALLUSERS=1",
            "TARGETDIR=`"$env:ProgramFiles\Microsoft\TeamsMeetingAdd-in\$Version`"",
            "REINSTALL=ALL",
            "REINSTALLMODE=vomus",
            "/L*vx! $env:ProgramData\Microsoft\IntuneManagementExtension\Logs\Software\Microsoft_Teams_Meeting_Add-in_for_Microsoft_Office_$($Version)_Reinstall.log"
        )
        PassThru = $true
    }
    $TeamsMeetingAddin = Start-Process @Install
    Wait-Process -Id $TeamsMeetingAddin.Id
    # Wait a bit longer
    Start-Sleep -Seconds 5
    # Splatting to pass the original downloaded MSI installer to msiexec to repair the install
    $Repair = @{
        FilePath = "$env:WINDIR\System32\msiexec.exe"
        ArgumentList = @(
            "/fa",
            "$MSTeamsMeetingAddinInstaller",
            "/qn",
            "/L*vx! $env:ProgramData\Microsoft\IntuneManagementExtension\Logs\Software\Microsoft_Teams_Meeting_Add-in_for_Microsoft_Office_$($Version)_Repair.log"
        )
        PassThru = $true
    }
    $TeamsMeetingAddin = Start-Process @Repair
    Wait-Process -Id $TeamsMeetingAddin.Id
    # Wait a bit longer
    Start-Sleep -Seconds 5
    # Remove the installer from %TEMP%
    Get-Item -Path $MSTeamsMeetingAddinInstallerInTemp | Remove-Item -Force -Confirm:$false
} Else {
    $ErrorCode = 9002
    $Exception = New-Object System.Management.Automation.RuntimeException "MSTeams-x64.msix failed to download, or was not found in: $env:TEMP"
    $ErrorRecord = New-Object System.Management.Automation.ErrorRecord $Exception, $ErrorCode, "OperationStopped", $null
    Throw $ErrorRecord
}
#EndRegion