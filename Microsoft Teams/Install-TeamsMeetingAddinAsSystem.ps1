<#
.DESCRIPTION
    Scripts for detecting and installing the Microsoft Teams Meeting Add-in for Microsoft Office in system context. This application should supersede another application that has it installed in user context
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
#Region: Install
$MSTeams = Get-AppxProvisionedPackage -Online | Where-Object {$_.PackageName -eq 'MSTeams'}
$MSTeamsInstallLocation = $MSTeams.InstallLocation -Replace('AppxManifest.xml','')
$MSTeamsMeetingAddinInstaller = "$MSTeamsInstallLocation\MicrosoftTeamsMeetingAddinInstaller.msi"
# Check if the Teams Meeting Add-in installer exists, and if so copy it to %TEMP% so we can load it and extract the version number, without effecting the original file
If (Test-Path -Path $MSTeamsMeetingAddinInstaller) {
    # If the installer exists, copy it to %TEMP%
    Copy-Item -Path $MSTeamsMeetingAddinInstaller -Destination "$env:TEMP" -Force
    $MSTeamsMeetingAddinInstallerInTemp = "$env:TEMP\MicrosoftTeamsMeetingAddinInstaller.msi"
    # Load the copied MSI so we can extract the version number
    $Installer = New-Object -ComObject WindowsInstaller.Installer
    $Database = $Installer.OpenDatabase($MSTeamsMeetingAddinInstallerInTemp, 0)
    $View = $Database.OpenView("SELECT * FROM Property WHERE Property = 'ProductVersion'")
    $View.Execute()
    $Record = $View.Fetch()
    $Version = $Record.StringData(1)
    # Create the folder for the version of the Teams Meeting Add-in installer
    New-Item -Path "$env:ProgramFiles\Microsoft\TeamsMeetingAdd-in\$Version" -ItemType Directory -Force
    # Splatting to pass the original MSI installer to msiexec to install the software
    $Install = @{
        FilePath = "$env:WINDIR\System32\msiexec.exe"
        ArgumentList = @(
            "/i",
            "$MSTeamsMeetingAddinInstaller",
            "/qn",
            "ALLUSERS=1",
            "TARGETDIR=`"$env:ProgramFiles\Microsoft\TeamsMeetingAdd-in\$Version`"",
            "/L*vx! $env:ProgramData\Microsoft\IntuneManagementExtension\Logs\Software\Microsoft_Teams_Meeting_Add-in_for_Microsoft_Office_$($Version)_Install.log"
        )
        PassThru = $true
    }
    $TeamsMeetingAddin = Start-Process @Install
    Wait-Process -Id $TeamsMeetingAddin.Id
    # Wait a bit longer
    Start-Sleep -Seconds 5
    # Remove the installer from %TEMP%
    Get-Item -Path $MSTeamsMeetingAddinInstallerInTemp | Remove-Item -Force -Confirm:$false
} Else {
    $ErrorCode = 9001
    $Exception = New-Object System.Management.Automation.RuntimeException "MicrosoftTeamsMeetingAddinInstaller.msi not found in folder: $MSTeamsInstallLocation"
    $ErrorRecord = New-Object System.Management.Automation.ErrorRecord $Exception, $ErrorCode, "OperationStopped", $null
    Throw $ErrorRecord
}
#EndRegion