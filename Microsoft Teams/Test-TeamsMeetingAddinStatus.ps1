<#
.SYNOPSIS
    Checks the status of the Microsoft Teams Meeting Add-in for Microsoft Office.
.DESCRIPTION
    Detection script of a Remediation to report the status of the Teams Meeting Add-in for Microsoft Office on the workstation. Where the InstallSource of the Teams Meeting Add-in does not match the InstallLocation of MSTeams, the add-in is considered to be in a broken state.
.NOTES
    This script is intended to be used as a detection method for reporting.
#>

#Region: Detection
$MSTeams = Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'MSTeams'}
$TeamsMeetingAddin = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall' | Get-ItemProperty | Where-Object {$_.DisplayName -eq 'Microsoft Teams Meeting Add-in for Microsoft Office'}
# If the Teams Meeting Add-in InstallSource matches the MSTeams InstallLocation, we can assume it's installed, if the Teams Meeting Add-in is not present, or doesn't match then it's not installed (or not installed properly)
If ($TeamsMeetingAddin -and $TeamsMeetingAddin.InstallSource -eq ([string]$MSteams.InstallLocation -Replace('AppxManifest.xml',''))) {
    Write-Output "The Teams Meeting Add-in InstallSource matches the MSTeams InstallLocation."
    Exit 0
} Else {
    Write-Output "The Teams Meeting Add-in InstallSource of '$($TeamsMeetingAddin.InstallSource)' does not match the MSTeams InstallLocation of '$($MSTeams.InstallLocation)', or the Add-in is not present."
    Exit 1
}
#EndRegion
#Region: Remediation

#EndRegion