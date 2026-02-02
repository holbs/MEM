<#
.SYNOPSIS
    Blocks Azure AD Workplace Join on the device.
.DESCRIPTION
    This script creates a registry key to block Azure AD Workplace Join on the device by setting the 'BlockAADWorkplaceJoin' DWORD value to 1 under 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WorkplaceJoin'.
#>

New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WorkplaceJoin' -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WorkplaceJoin' -Name 'BlockAADWorkplaceJoin' -Value '1' -Type DWord -Force | Out-Null