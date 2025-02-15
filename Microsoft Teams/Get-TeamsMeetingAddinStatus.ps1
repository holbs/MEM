<#
.DESCRIPTION
    This script is deployed as a configuration item to check if Microsoft Teams Add-in for Microsoft Office is in a broken state and the Teams Meeting Add-in is not loading in Outlook.
    This is usually caused by some sort of upgrade issues as Teams upgrades, and is detected when the InstallSource of the Teams Meeting Add-in is not the same as the Teams installation path.
    This reports compliant if Microsoft Teams Add-in for Microsoft Office is installed, and the InstallSource matches the MSTeams InstallLocation
#>

#Requires -RunAsAdministrator

#Region: Detection
$MSTeams = Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq 'MSTeams'}
$TeamsMeetingAddin = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall' | Get-ItemProperty | Where-Object {$_.DisplayName -eq 'Microsoft Teams Meeting Add-in for Microsoft Office'}
# If the Teams Meeting Addin InstallSource matches the MSTeams InstallLocation, we can assume it's installed, if the Teams Meeting Addin is not present, or doesn't match then it's not installed (properly)
If ($TeamsMeetingAddin -and $TeamsMeetingAddin.InstallSource -eq ([string]$MSteams.InstallLocation -Replace('AppxManifest.xml',''))) {
    Return $true
} Else {
    Return $false
}
#EndRegion
#Region: Remediation

#EndRegion