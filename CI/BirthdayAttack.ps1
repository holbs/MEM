#Region: Detection
Try {
    $TripleDES168 = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\Triple DES 168' -ErrorAction Stop
    If ($TripleDES168.Enabled -ne 0) {
        Return $false
    }
} Catch {
    Return $false
}
Return $true
#EndRegion
#Region: Remediation
New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\Triple DES 168' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\Triple DES 168' -Name 'Enabled' -Value '0' -Type DWord -Force | Out-Null
#EndRegion
