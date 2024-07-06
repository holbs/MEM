#Region: Detection
$KernelEvents = Get-WinEvent -ProviderName 'Microsoft-Windows-Kernel-Boot'
$KernelReboot = $KernelEvents | Where-Object {$_.Id -eq 27 -and $_.Message -eq "The boot type was 0x0."}
If ($KernelReboot[0].TimeCreated -ge (Get-Date).AddDays(-7)) {
    Return $true
} Else {
    Return $false
}
#EndRegion
#Region: Remediation
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\SMS\Mobile Client\Reboot Management\RebootData' -Name 'RebootBy' -Value $Time -Type QWord -Force -ErrorAction SilentlyContinue
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\SMS\Mobile Client\Reboot Management\RebootData' -Name 'RebootValueInUTC' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\SMS\Mobile Client\Reboot Management\RebootData' -Name 'NotifyUI' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\SMS\Mobile Client\Reboot Management\RebootData' -Name 'HardReboot' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\SMS\Mobile Client\Reboot Management\RebootData' -Name 'OverrideRebootWindowTime' -Value 0 -Type QWord -Force -ErrorAction SilentlyContinue
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\SMS\Mobile Client\Reboot Management\RebootData' -Name 'OverrideRebootWindow' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\SMS\Mobile Client\Reboot Management\RebootData' -Name 'PreferredRebootWindowTypes' -Value @("4") -Type MultiString -Force -ErrorAction SilentlyContinue
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\SMS\Mobile Client\Reboot Management\RebootData' -Name 'GraceSeconds' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
# Restart ccmexec so the above settings are used and prompts the user to restart
Start-Job -ScriptBlock {
    Start-Sleep -Seconds 10
    Start-Process -FilePath "$env:WINDIR\CCM\CcmRestart.exe"
}
#EndRegion
