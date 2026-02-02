<#
.SYNOPSIS
    Aligns the taskbar to the left in Windows 11.
.DESCRIPTION
    This script modifies the registry to set the taskbar alignment to the left side of the screen in Windows 11 by changing the 'TaskbarAl' DWORD value to 0 under 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'.
.NOTES
    This script modifies the registry under the current user context. 
#>

New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 0 -Force | Out-Null