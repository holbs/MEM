#Region: Detection
$ConnectionProfileCost = [Windows.Networking.Connectivity.NetworkInformation, Windows.Networking.Connectivity, ContentType = WindowsRuntime]::GetInternetConnectionProfile().GetConnectionCost()
If ($ConnectionProfileCost.NetworkCostType -eq [Windows.Networking.Connectivity.NetworkCostType]::Unrestricted) {
    Return $true
} Else {
    Return $false
}
#EndRegion
#Region: Remediation
$ActiveAdaptersGuids = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -ExpandProperty InterfaceGuid
Foreach ($Guid in $ActiveAdaptersGuids) {
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\DusmSvc\Profiles\$Guid\*" -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DusmSvc\Profiles\$Guid\*" -Name UserCost -Value 0 -Type DWord -Force | Out-Null
    Restart-Service -Name DusmSvc -Force
}
#EndRegion