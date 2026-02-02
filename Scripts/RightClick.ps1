<#
.SYNOPSIS
    Sets the right click menu in Windows 11 to default straight to the 'Show more options' menu.
.DESCRIPTION
    This script creates the necessary registry keys to modify the right-click context menu behaviour in Windows 11, making it default to the classic 'Show more options' menu instead of the new simplified menu.
.NOTES
    This script modifies the registry under the current user context. A restart of the Explorer process is required for the changes to take effect.
#>

New-Item -Path "HKCU:\SOFTWARE\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Force | Out-Null
New-Item -Path "HKCU:\SOFTWARE\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Force | Out-Null
# Force the Explorer process to restart to apply the changes
Stop-Process -ProcessName "Explorer"