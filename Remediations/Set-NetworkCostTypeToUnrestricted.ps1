<#
.SYNOPSIS
    This script checks if the current network connection is metered and, if so, changes it to unmetered.
.DESCRIPTION
    The script detects if the active network connection is set to metered. If it is metered, the script modifies the registry settings for all active network adapters to set them as unmetered.
.NOTES
    This script uses Windows Runtime APIs to determine the network cost type.
#>

#Region: Detection
$ConnectionProfileCost = [Windows.Networking.Connectivity.NetworkInformation, Windows.Networking.Connectivity, ContentType = WindowsRuntime]::GetInternetConnectionProfile().GetConnectionCost()
If ($ConnectionProfileCost.NetworkCostType -eq [Windows.Networking.Connectivity.NetworkCostType]::Unrestricted) {
    Write-Output "The network connection is unmetered."
    Exit 0
} Else {
    Write-Output "The network connection is metered."
    Exit 1
}
#EndRegion
#Region: Remediation
$ActiveAdaptersGuids = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -ExpandProperty InterfaceGuid
Foreach ($Guid in $ActiveAdaptersGuids) {
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\DusmSvc\Profiles\$Guid\*" -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DusmSvc\Profiles\$Guid\*" -Name UserCost -Value 0 -Type DWord -Force | Out-Null
}
# Restart the Data Usage service to commit the changes
Restart-Service -Name DusmSvc -Force
#EndRegion