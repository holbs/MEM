<#
.SYNOPSIS
    Disables DES and Triple DES ciphers to mitigate Birthday Attack vulnerabilities, specifically the SWEET32 vulnerability (CVE-2016-2183).
.DESCRIPTION
    This script checks if DES and Triple DES ciphers are disabled on the system. If they are not disabled, it disables them by setting the appropriate registry keys.
.NOTES
    We are using .CreateSubKey() method to avoid issues with New-ItemProperty creating additional keys when the key has a / in its name.
#>

#Region: Detection
$DES = Get-ItemPropertyValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\DES 56/56" -Name 'Enabled' -ErrorAction SilentlyContinue
$TripleDES = Get-ItemPropertyValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\Triple DES 168" -Name 'Enabled' -ErrorAction SilentlyContinue
If ($DES -eq 0 -and $TripleDES -eq 0) {
    Write-Output "DES and Triple DES are both set to disabled"
    Exit 0
} Else {
    Write-Output "DES and Triple DES are not both set to disabled"
    Exit 1
}
#EndRegion
#Region: Remediation
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers" -ErrorAction SilentlyContinue | Out-Null
$Ciphers = (Get-Item -Path "HKLM:\").OpenSubKey("SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers", $true)
$Ciphers.CreateSubKey('DES 56/56')
$Ciphers.CreateSubKey('Triple DES 168')
$Ciphers.Close()
# Set Enabled to 0 to disable the ciphers
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\DES 56/56" -Name 'Enabled' -Value 0 -Type DWord -Force | Out-Null
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\Triple DES 168" -Name 'Enabled' -Value 0 -Type DWord -Force | Out-Null
#EndRegion