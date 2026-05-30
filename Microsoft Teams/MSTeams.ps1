<#
.SYNOPSIS
    Detection, installation, repair, and uninstallation scripts to install MSTeams (and keep it up to date if it falls behind).
.DESCRIPTION
    Detection script checks if Teams is installed, and if ms-teams.exe is less than 90 days old. If not detection fails and the installation script runs. The installation script installs MSTeams using the packaged teamsbootstrapper.exe and the latest MSIX.
.NOTES
    These scripts written to work as a Configuration Manager application so detection is based on exit code 0 AND something being in stdout. Exit code 0 with nothing in stdout is treated as detection failure.
#>

#Region: Detection
$MSTeamsProvisionedPackage = Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq "MSTeams"}
If (-not $MSTeamsProvisionedPackage) {
    # MSTeams is not installed
    Exit 0
} Else {
    # MSTeams is installed, locate ms-teams.exe and check the CreationTime, if it's less than 90 days old then for the purposes of this script MSTeams is installed. If it's 90 days or older then for the purposes of this script it's not installed and we should trigger installation
    $MSTeamsInstallLocation = Join-Path -Path (Split-Path $MSTeamsProvisionedPackage.InstallLocation -Parent) -ChildPath 'ms-teams.exe'
    If (-not (Test-Path -Path $MSTeamsInstallLocation -PathType Leaf)) {
        # ms-teams could not be located. Treat as not installed
        Exit 0
    } Else {
        $CreationTime = (Get-Item -Path $MSTeamsInstallLocation).CreationTime
        If ($CreationTime -gt (Get-Date).AddDays(-90)) {
            # MSTeams is installed and less than 90 days old. Exit with something in stdout to meeting detection criteria and do nothing
            Write-Output "MSTeams is installed"
            Exit 0
        } Else {
            # MSTeams is installed but 90 days or older
            Exit 0
        }
    }
}
#EndRegion
#Region: Install
& "$env:PSScriptRoot\teamsbootstrapper.exe" -p -o "$env:PSScriptRoot\MSTeams-x64.msix"
Exit $LASTEXITCODE
#EndRegion
#Region: Repair
& "$env:PSScriptRoot\teamsbootstrapper.exe" -p
Exit $LASTEXITCODE
#EndRegion
#Region: Uninstall
& "$env:PSScriptRoot\teamsbootstrapper.exe" -x
Exit $LASTEXITCODE
#EndRegion